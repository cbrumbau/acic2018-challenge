#!/usr/bin/env Rscript
#
# Rscript generate_random_forests.R --include --merge imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/09/2018

library("optparse")
library("tools")
library("randomForest")

option_list <- list(
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific features to use for training the random forest [default %default]"),
	make_option(c("-m", "--merge"), type="logical", default=FALSE, 
		help="merge the imputation random forest models by data set and do not compute the random forests [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] imputations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

if (nchar(opt$options$include[1]) > 0) {
	include <- scan(opt$options$include[1], what=character())
}

rforest <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE, sep=",")
	result <- tryCatch({
		this.x <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
		this.y <- this.set[, c("y")]
		if (nchar(opt$options$include[1]) > 0) {
			system.time(this.rf <- randomForest(this.x[, include], y=this.y))
		} else {
			system.time(this.rf <- randomForest(this.x, y=this.y))
		}
	}, warning = function(w) {
		print(paste("WARNING: ", w))
	}, error = function(e) {
		print(paste("ERROR: ", e))
	}, finally = {
		print("Saving model...")
		saveRDS(this.rf, file=paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), ".rds", sep=""))
	})
 }

if (opt$options$merge[1]) {
	files <- list.files(path=opt$args[2])
	# Categorize imputations belonging to each data set from the files
	files.set = list()
	for (this.file in files) {
		this.dataset <- gsub("_\\d+\\.rds", "", this.file, ignore.case=T)
		if (this.dataset %in% names(files.set)) {
			files.set[[this.dataset]] <- append(files.set[[this.dataset]], this.file)
		} else {
			files.set[this.dataset] <- list(this.file)
		}
	}
	# Read in all the randomForest objects for each data set
	for (this.dataset in names(files.set)) {
		models.set = list()
		for (this.rds in files.set[[this.dataset]]) {
			models.set[[length(models.set)+1]] <- readRDS(paste(opt$args[2], this.rds, sep=""))
		}
		# Merge into one model and write this output
		print(paste("Merging random forest models for ", this.dataset))
		merged.rf <- do.call("combine", models.set)
		print("Saving merged model...")
		saveRDS(merged.rf, file=paste(paste(opt$args[2], this.dataset, sep=""), ".rds", sep=""))
	}
} else {
	files <- list.files(path=opt$args[1])
	invisible(lapply(files, rforest))
}
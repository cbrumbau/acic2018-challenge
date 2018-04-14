#!/usr/bin/env Rscript
#
# Rscript generate_random_forests.R --merge imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/09/2018

library("optparse")
library("tools")
library("randomForest")

option_list <- list(
	make_option(c("-m", "--merge"), type="logical", default=FALSE, 
		help="merge the imputation random forest models by data set and do not compute the random forests [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] imputations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

rforest <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE, sep=",")
	this.x <- this.set[, !(names(this.set) %in% c("X","sample_id","z","y"))]
	this.y <- this.set[, c("y")]
	result = tryCatch({
		this.rf <- randomForest(this.x, y=this.y)
	}, warning = function(w) {
		print(paste("WARNING: ", w))
	}, error = function(e) {
		print(paste("ERROR: ", e))
	}, finally = {
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
			files.set[[this.dataset]] <- c(files.set[[this.dataset]], this.file)
		} else {
			files.set[[this.dataset]] <- c(this.file)
		}
	}
	# Read in all the randomForest objects for each data set
	for (this.dataset in names(files.set)) {
		models.set = list()
		for (this.rds in files.set[[this.dataset]]) {
			this.rf <- readRDS(paste(opt$args[2], this.rds, sep=""))
			models.set <- c(models.set, this.rf)
		}
		# Merge into one model and write this output
		merged.rf <- do.call("combine", models.set)
		saveRDS(merged.rf, file=paste(paste(opt$args[2], this.dataset, sep=""), ".rds", sep=""))
	}
} else {
	files <- list.files(path=opt$args[1])
	invisible(lapply(files, rforest))
}
#!/usr/bin/env Rscript
#
# Rscript generate_random_forests.R --merge imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/15/2018

library("h2o")
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
	train.h2o <- as.h2o(this.set[, !names(this.set) %in% c("X", "sample_id", "z")])
	x.indep <- c(1:grep("^y$", colnames(train.h2o))-1)
	y.dep <- grep("^y$", colnames(train.h2o))
	result <- tryCatch({
		this.rf <- h2o.randomForest(y=y.dep, x=x.indep, training_frame=train.h2o, ntrees=500)
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
	localH2O <- h2o.init()
	files <- list.files(path=opt$args[1])
	invisible(lapply(files, rforest))
	h2o.shutdown(prompt=FALSE)
}
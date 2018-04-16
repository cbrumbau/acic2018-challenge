#!/usr/bin/env Rscript
#
# Rscript predict_using_random_forests.R --threads rforest_model.rds exclude_file test_folder output_folder
# This R script generates predictions using a random forest model file from a test set folder to an output folder as csv files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/16/2018

library("doMC")
library("optparse")
library("randomForest")

option_list <- list(
	make_option(c("-t", "--threads"), type="integer", default=4,
		help="number of threads to use for parallel predictions to run on the test set(s) [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] rforest_model.rds exclude_file test_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=4)
registerDoMC()

# Read in the model and exclude files
print("Reading in model...")
this.rf <- readRDS(opt$args[1])
exclude <- scan(opt$args[2], what=character())

# Get all the test set files and process in chunks for the number of requested threads
test.files <- list.files(path=opt$args[3])
for (files.list in split(test.files, ceiling(seq_along(test.files)/opt$options$threads[1]))) {
	# Remove excluded columns from imputations and non-test set columns
	test.set <- list()
	for (file in files.list) {
		test.set[[length(test.set)+1]] <- read.csv(file=paste(opt$args[3], file, sep=""), header=TRUE, sep=",")
	}
	excluded.x <- list()
	for (this.set in test.set) {
		this.set <- this.set[, !names(this.set) %in% exclude]
		excluded.x[[length(excluded.x)+1]] <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
	}
	print(paste("Processing", files.list, sep=" "))
	# Predict the files in parallel
	predict.rf <- foreach(test.data=excluded.x, .inorder=TRUE, .packages='randomForest') %dopar% {
		predict(this.rf, test.data)
	}
	# Write the results to file
	print("Writing predicted values to file...")
	for (i in 1:length(predict.rf)) {
		write.csv(predict.rf[i], file=paste(opt$args[4], files.list[i], sep=""), quote=FALSE)
	}
}
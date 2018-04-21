#!/usr/bin/env Rscript
#
# Rscript predict_using_random_forests.R --include --exclude --threads rforest_model.rds test_folder output_folder
# This R script generates predictions using a random forest model file from a test set folder to an output folder as csv files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/16/2018

library("doMC")
library("optparse")
library("tools")
library("randomForest")

option_list <- list(
	make_option(c("-e", "--exclude"), type="character", default="", 
		help="file containing specific features to exclude, cannot be used with include [default %default]"),
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific features to include, cannot be used with exclude [default %default]"),
	make_option(c("-t", "--threads"), type="integer", default=4,
		help="number of threads to use for parallel predictions to run on the test set(s) [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] rforest_model.rds test_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=3)
registerDoMC()

if (nchar(opt$options$exclude[1]) > 0) {
	exclude <- scan(opt$options$exclude[1], what=character())
} else if (nchar(opt$options$include[1]) > 0) {
	include <- scan(opt$options$include[1], what=character())
}

# Read in the model
print("Reading in model...")
this.rf <- readRDS(opt$args[1])

# Get all the test set files and process in chunks for the number of requested threads
test.files <- list.files(path=opt$args[2])
for (files.list in split(test.files, ceiling(seq_along(test.files)/opt$options$threads[1]))) {
	# Process test sets and apply exclusion or inclusion if requested
	test.set <- list()
	for (file in files.list) {
		test.set[[length(test.set)+1]] <- read.csv(file=paste(opt$args[3], file, sep=""), header=TRUE, sep=",")
	}
	x.list <- list()
	for (this.set in test.set) {
		if (nchar(opt$options$exclude[1]) > 0) {
			this.set <- this.set[, !names(this.set) %in% exclude]
		} else if (nchar(opt$options$include[1]) > 0) {
			this.set <- this.set[, include]
		}
		x.list[[length(x.list)+1]] <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
	}
	print(paste("Processing", files.list, sep=" "))
	# Predict the files in parallel
	start.time <- Sys.time()
	predict.rf <- foreach(test.data=x.list, .inorder=TRUE, .packages='randomForest') %dopar% {
		predict(this.rf, test.data)
	}
	print(Sys.time()-start.time)
	# Write the results to file
	print("Writing predicted values to file...")
	for (i in 1:length(predict.rf)) {
		write.table(predict.rf[[i]], file=paste(opt$args[3], tools::file_path_sans_ext(files.list[i]), ".txt", sep=""), quote=FALSE, row.names=FALSE, col.names=FALSE)
	}
}
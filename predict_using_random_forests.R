#!/usr/bin/env Rscript
#
# Rscript predict_using_random_forests.R --threads model_folder test_folder output_folder
# This R script generates predictions using a random forest model file from a test set folder to an output folder as csv files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/16/2018

library("doMC")
library("optparse")
library("tools")
library("randomForest")

option_list <- list(
	make_option(c("-t", "--threads"), type="integer", default=4,
		help="number of threads to use for parallel predictions to run on the test sets [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] rforest_model.rds test_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=3)
registerDoMC()

# Get all the test set files and process in chunks for the number of requested threads
test.files <- list.files(path=opt$args[2])
for (files.list in split(test.files, ceiling(seq_along(test.files)/opt$options$threads[1]))) {
	# Process test sets and corresponding models
	print("Processing chunk for test sets and corresponding models...")
	untreated.model.list <- list()
	treated.model.list <- list()
	test.list <- list()
	for (file in files.list) {
		untreated.model.list[[length(untreated.model.list)+1]] <- readRDS(file=paste(opt$args[1], tools::file_path_sans_ext(file), "_untreated.rds", sep=""))
		treated.model.list[[length(treated.model.list)+1]] <- readRDS(file=paste(opt$args[1], tools::file_path_sans_ext(file), "_treated.rds", sep=""))
		test.list[[length(test.list)+1]] <- read.csv(file=paste(opt$args[2], file, sep=""), header=TRUE)
	}
	x.list <- list()
	for (i in 1:length(files.list)) {
		this.set <- test.list[[i]]
		# Filter test set for independent variables used in model construction
		include <- names(untreated.model.list[[i]]$forest$xlevels)
		x.list[[length(x.list)+1]] <- this.set[, include]
	}
	# Predict the files in parallel for each model
	print(paste("Predicting", files.list, sep=" "))
	start.time <- Sys.time()
	predict.treated <- foreach(test.data=x.list, this.rf=treated.model.list, .inorder=TRUE, .packages='randomForest') %dopar% {
		predict(this.rf, test.data)
	}
	print(Sys.time()-start.time)
	start.time <- Sys.time()
	predict.untreated <- foreach(test.data=x.list, this.rf=untreated.model.list, .inorder=TRUE, .packages='randomForest') %dopar% {
		predict(this.rf, test.data)
	}
	print(Sys.time()-start.time)
	# Create data frame containing sample_id, y0, y1
	print("Generating prediction output...")
	predict.list <- list()
	for (i in 1:length(files.list)) {
		sample_id <- test.list[[i]]$sample_id
		y0 <- predict.untreated[[i]]
		y1 <- predict.treated[[i]]
		predict.list[[length(predict.list)+1]] <- data.frame(sample_id, y0, y1)
	}
	# Write the results to file
	print("Writing predicted values to file...")
	for (i in 1:length(files.list)) {
		write.csv(predict.list[[i]], file=paste(opt$args[3], tools::file_path_sans_ext(files.list[i]), ".csv", sep=""), quote=FALSE, row.names=FALSE)
	}
}
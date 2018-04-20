#!/usr/bin/env Rscript
#
# Rscript random_forest_feature_selection.R input.csv output.rds
# This R script performs cross validation for feature selection, input as a csv used to build a random forest model and output as an rds file containing a list of error rates with corresponding predicted values.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/16/2018

library("optparse")
library("randomForest")

option_list <- list(
	make_option(c("-f", "--folds"), type="integer", default=5,
		help="number of folds to use for cross validation [default %default]", metavar="number"),
	make_option(c("-s", "--step"), type="double", default=0.5,
		help="the fraction of variables to remove at each step [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] input.csv output.rds", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

# Read in the features from the csv
this.set <- read.csv(file=opt$args[1], header=TRUE, sep=",")

# Perform the feature selection
start.time <- Sys.time()
result.list <- rfcv(this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")], this.set[, c("y")], cv.fold=opt$options$folds[1], step=opt$options$step[1])
print(Sys.time()-start.time)

# Save to file
saveRDS(result.list, file=opt$args[2])
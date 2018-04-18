#!/usr/bin/env Rscript
#
# Rscript linear_regression_feature_selection.R input.csv output.txt
# This R script performs correlation testing for feature selection, input of features as a csv and output as a text file containing features that were found to not be correlated.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/17/2018

library("caret")
library("mlbench")
library("optparse")

option_list <- list(
	make_option(c("-c", "--cutoff"), type="double", default=0.75,
		help="the pairwise absolute correlation cutoff [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] input.csv output.txt", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

# Read in the features from the csv
this.set <- read.csv(file=opt$args[1], header=TRUE, sep=",")

# Calculate correlation matrix
this.set <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
correlation.matrix <- cor(this.set)

# Determine highly corrected features
highly.correlated <- findCorrelation(correlation.matrix, cutoff=opt$options$cutoff[1])

# Save to file
write.table(names(this.set[, -highly.correlated]), file=opt$args[2], quote=FALSE, row.names=FALSE, col.names=FALSE)
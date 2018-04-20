#!/usr/bin/env Rscript
#
# Rscript random_forest_extract_importance.R input_model.rds output_matrix.rds
# This R script extracts the importance values from a random forest model.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/19/2018

library("optparse")
library("randomForest")

opt_parser <- OptionParser(usage = "%prog [options] input_model.rds output_matrix.rds")
opt <- parse_args(opt_parser, positional_arguments=2)

# Read in the model
this.rf <- readRDS(file=opt$args[1])

# Save to file
saveRDS(this.rf$importance, file=opt$args[2])
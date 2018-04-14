#!/usr/bin/env Rscript
#
# Rscript merge_all_forests.R model_folder output_file
# This R script merges all random forests objects in RDS files from a model folder and writes to an output file.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/14/2018

library("optparse")
library("randomForest")

opt_parser <- OptionParser(usage = "%prog [options] model_folder output_file")
opt <- parse_args(opt_parser, positional_arguments=2)

# Read in all rds files from the model folder
print("Reading in model files...")
files <- list.files(path=opt$args[1])
models.list = list()
for (this.rds in files) {
	models.list[[length(models.list)+1]] <- readRDS(paste(opt$args[1], this.rds, sep=""))
}
# Combine into a single model
print("Merging all random forest models...")
merged.rf <- do.call("combine", models.list)
# Write to output
print("Saving model to file...")
saveRDS(merged.rf, file=opt$args[2])
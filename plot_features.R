#!/usr/bin/env Rscript
#
# Rscript plot_features.R --graphs input.csv output_folder
# This R script generates histograms of features from a input.csv to an output folder as pdf files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/19/2018

library("optparse")
library("sfsmisc")
library("tools")

option_list <- list(
	make_option(c("-g", "--graphs"), type="integer", default=4,
		help="number of graphs to plot on one page [default %default]"),
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific features to use (if features have been selected) [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] input.csv output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

# Read in the features (and process inclusion list if provided)
print("Reading in features...")
this.set <- read.csv(opt$args[1], header=TRUE)
this.set <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
if (nchar(opt$options$include[1]) > 0) {
	include <- scan(opt$options$include[1], what=character())
	this.set <- this.set[, include]
}

# Graph the features
print("Plotting features...")
column.names <- names(this.set)
for (column.list in split(column.names, ceiling(seq_along(column.names)/opt$options$graphs[1]))) {
	pdf(file=paste(opt$args[2], paste(column.list, collapse="-"), ".pdf", sep=""))
	par(mult.fig(opt$options$graphs[1])$new.par)
	for (i in 1:length(column.list)) {
		hist(this.set[, column.list[[i]]], main=column.list[[i]], xlab=column.list[[i]], col="grey")
	}
	dev.off()
}
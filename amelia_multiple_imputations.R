#!/usr/bin/env Rscript
#
# Rscript amelia_multiple_imputations.R --exclude --imputations observations_folder output_folder
# This R script generates multiple imputations from an observations folder to an output folder as csv files and excludes named columns from Amelia in an exclude text file.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/04/2018

library("optparse")
library("tools")
library("Amelia")

option_list <- list(
	make_option(c("-e", "--exclude"), type="character", default="", 
		help="folder to write text files containing any colinear variables that were excluded from multiple imputations [default %default]"),
	make_option(c("-i", "--imputations"), type="integer", default=5, 
		help="number of imputations to generate [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] observations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

mimput <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE)
	result <- tryCatch({
		start.time <- Sys.time()
		a.out <- amelia(this.set, m=opt$options$number[1], idvars=c("sample_id"), empri=0.01*nrow(this.set))
		print(Sys.time()-start.time)
	}, warning = function(w) {
		message(paste("WARNING: ", w))
		# Try again, with warnings removed from the columns
		exclude <- strsplit(gsub("simpleWarning in amcheck\\(x = x, m = m, idvars = numopts\\$idvars, priors = priors, : |The variable |is perfectly collinear with another variable in the data.\n|\n", "", w), " ")
		if (nchar(opt$options$exclude[1]) > 0) {
			write.table(exclude, file=paste(opt$options$exclude[1], tools::file_path_sans_ext(filename), "_exclude.txt", sep=""), row.names=FALSE, col.names=FALSE)
		}
		this.set <- this.set[, !(names(this.set) %in% exclude)]
		start.time <- Sys.time()
		a.out <- amelia(this.set, m=opt$options$number[1], idvars=c("sample_id"), empri=0.01*nrow(this.set))
		print(Sys.time()-start.time)
	}, error = function(e) {
		message(paste("ERROR: ", e))
	}, finally = {
		write.amelia(obj=a.out, file.stem=paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), "_", sep=""), quote=FALSE, row.names=FALSE)
	})
 }
 
files <- list.files(path=opt$args[1])
invisible(lapply(files, mimput))
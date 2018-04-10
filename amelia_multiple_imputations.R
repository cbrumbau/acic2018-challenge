#!/usr/bin/env Rscript
#
# Rscript amelia_multiple_imputations.R --number=number_of_imputations observations_folder output_folder exclude_file
# This R script generates multiple imputations from an observations folder to an output folder as csv files and excludes named columns from Amelia in an exclude text file.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/04/2018

library("optparse")
library("tools")
library("Amelia")

option_list <- list(
	make_option(c("-n", "--number"), type="integer", default=5, 
		help="number of imputations to generate [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] observations_folder output_folder exclude_file", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=3)

exclude <- scan(opt$args[3], what=character())

mimput <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	df <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE, sep=",")
	# from manual examination of warnings for colinearlity for these data sets
	result = tryCatch({
		a.out <- amelia(df[, !(names(df) %in% exclude)], m=opt$options$number[1], idvars=c("sample_id"), empri=0.01*nrow(df))
	}, warning = function(w) {
		print(paste("WARNING: ",w))
	}, error = function(e) {
		print(paste("ERROR: ",e))
	}, finally = {
		write.amelia(obj=a.out, file.stem = paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), "_", sep=""), quote=FALSE)
	})
 }
 
files <- list.files(path=opt$args[1])
invisible(lapply(files, mimput))
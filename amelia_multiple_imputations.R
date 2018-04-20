#!/usr/bin/env Rscript
#
# Rscript amelia_multiple_imputations.R --exclude --number observations_folder output_folder
# This R script generates multiple imputations from an observations folder to an output folder as csv files and excludes named columns from Amelia in an exclude text file.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/04/2018

library("optparse")
library("tools")
library("Amelia")

option_list <- list(
	make_option(c("-e", "--exclude"), type="character", default="", 
		help="file containing specific features to exclude from multiple imputations [default %default]"),
	make_option(c("-n", "--number"), type="integer", default=5, 
		help="number of imputations to generate [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] observations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

if (nchar(opt$options$exclude[1]) > 0) {
	exclude <- scan(opt$options$exclude[1], what=character())
}

mimput <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE)
	if (nchar(opt$options$exclude[1]) > 0) {
		# from manual examination of warnings for colinearlity for these data sets, remove the excluded columns
		this.set <- this.set[, !(names(this.set) %in% exclude)]
	}
	result <- tryCatch({
		start.time <- Sys.time()
		a.out <- amelia(this.set, m=opt$options$number[1], idvars=c("sample_id"), empri=0.01*nrow(this.set))
		print(Sys.time()-start.time)
	}, warning = function(w) {
		print(paste("WARNING: ", w))
	}, error = function(e) {
		print(paste("ERROR: ", e))
	}, finally = {
		write.amelia(obj=a.out, file.stem=paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), "_", sep=""), quote=FALSE)
	})
 }
 
files <- list.files(path=opt$args[1])
invisible(lapply(files, mimput))
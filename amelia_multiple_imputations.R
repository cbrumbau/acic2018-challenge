#!/usr/bin/env Rscript
#
# Rscript amelia_multiple_imputations.R --imputations observations_folder output_folder
# This R script generates multiple imputations from an observations folder to an output folder as csv files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/04/2018

library("Amelia")
library("optparse")
library("tools")

option_list <- list(
	make_option(c("-i", "--imputations"), type="integer", default=5,
		help="number of imputations to generate [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] observations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

mimput <- function(filename, exclude=list()) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE)
	if (!anyNA(this.set)) {
		# Avoid Amelia Error Code 39 to continue script
		print("Has no missing values to impute")
		return(NA)
	}
	a.out <- NULL
	attempt <- 1
	exclude <- c()
	while (is.null(a.out) && attempt <= 10) {
		attempt <- attempt + 1
		this.set <- this.set[, !names(this.set) %in% exclude]
		result <- tryCatch({
			start.time <- Sys.time()
			a.out <- amelia(this.set, m=opt$options$imputations[1], idvars=c("sample_id"), empri=0.01*nrow(this.set))
			print(Sys.time()-start.time)
		}, warning = function(w) {
			message(paste("WARNING: ", w))
			# Try again, with warnings removed from the columns
			exclude <<- unlist(c(exclude, strsplit(gsub("simpleWarning in amcheck\\(x = x, m = m, idvars = numopts\\$idvars, priors = priors, : |The variable |is perfectly collinear with another variable in the data.\n|\n", "", w), " ")))
		}, error = function(e) {
			message(paste("ERROR: ", e))
		}, finally = {
			if (!is.null(a.out)){
				write.amelia(obj=a.out, file.stem=paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), "_", sep=""), quote=FALSE, row.names=FALSE)
			}
		})
	}
 }
 
files <- list.files(path=opt$args[1])
invisible(lapply(files, mimput))
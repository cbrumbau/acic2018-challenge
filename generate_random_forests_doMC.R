#!/usr/bin/env Rscript
#
# Rscript generate_random_forests_doMC.R --include imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/15/2018

library("doMC")
library("optparse")
library("tools")
library("randomForest")

option_list <- list(
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific predictors to exclusively use for training the random forest [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] imputations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)
registerDoMC()

if (nchar(opt$options$include[1]) > 0) {
	include <- scan(opt$options$include[1], what=character())
}

splitbyset <- function(filelist) {
	byset <- list()
	for (this.file in filelist) {
		this.file.noext <- tools::file_path_sans_ext(this.file)
		this.dataset <- gsub("_\\d+", "", this.file.noext, ignore.case=T)
		if (this.dataset %in% names(byset)) {
			byset[[this.dataset]] <- append(byset[[this.dataset]], this.file)
		} else {
			byset[this.dataset] <- list(this.file)
		}
	}
	return(byset)
}

rforest <- function(dataset.name, imputation.list) {
	print(paste("Processing ", dataset.name, sep=""))
	# Read in all imputed data
	imputed.set <- list()
	for (file in imputation.list) {
		imputed.set[[length(imputed.set)+1]] <- read.csv(file=paste(opt$args[1], file, sep=""), header=TRUE, sep=",")
	}
	imputed.x <- list()
	imputed.y <- list()
	for (this.set in imputed.set) {
		imputed.x[[length(imputed.x)+1]] <- this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")]
		if (nchar(opt$options$include[1]) > 0) {
			imputed.x[[length(imputed.x)]] <- this.set[, include]
		}
		imputed.y[[length(imputed.y)+1]] <- this.set[, c("y")]
	}
	print(paste("Generating random forests for", imputation.list, sep=" "))
	# Use nested foreach to first subdivide each data set, then subdivide by trees on a data set
	start.time <- Sys.time()
	this.rf <- foreach(this.x=imputed.x, this.y=imputed.y, .combine=combine, .multicombine=TRUE, .packages='randomForest') %:%
		foreach(ntree=rep(100, 5), .combine=combine, .multicombine=TRUE, .packages='randomForest') %dopar% {
			randomForest(x=this.x, y=this.y, ntree=ntree, importance=TRUE)
		}
	print(Sys.time()-start.time)
	# Save merged forest
	print("Saving model...")
	saveRDS(this.rf, file=paste(paste(opt$args[2], dataset.name, sep=""), ".rds", sep=""))
 }

files <- list.files(path=opt$args[1])
files.set <- splitbyset(files)
for (this.dataset in names(files.set)) {
	rforest(this.dataset, files.set[[this.dataset]])
}
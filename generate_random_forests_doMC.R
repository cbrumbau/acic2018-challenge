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
		help="file containing specific features to use for training the random forest [default %default]")
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
	treated.x <- list()
	treated.y <- list()
	untreated.x <- list()
	untreated.y <- list()
	for (this.set in imputed.set) {
		# Process treated rows
		treated.set <- subset(this.set, z==1)
		treated.x[[length(treated.x)+1]] <- treated.set[, !names(treated.set) %in% c("sample_id", "z", "y")]
		if (nchar(opt$options$include[1]) > 0) {
			treated.x[[length(treated.x)]] <- treated.set[, include]
		}
		treated.y[[length(treated.y)+1]] <- treated.set[, c("y")]
		# Process untreated rows
		untreated.set <- subset(this.set, z==0)
		untreated.x[[length(untreated.x)+1]] <- untreated.set[, !names(untreated.set) %in% c("sample_id", "z", "y")]
		if (nchar(opt$options$include[1]) > 0) {
			untreated.x[[length(untreated.x)]] <- untreated.set[, include]
		}
		untreated.y[[length(untreated.y)+1]] <- untreated.set[, c("y")]
	}
	print(paste("Generating random forests for", imputation.list, sep=" "))
	# Use nested foreach to first subdivide each data set, then subdivide by trees on a data set for treated/untreated
	start.time <- Sys.time()
	treated.rf <- foreach(this.x=treated.x, this.y=treated.y, .combine=combine, .multicombine=TRUE, .packages='randomForest') %:%
		foreach(ntree=rep(100, 5), .combine=combine, .multicombine=TRUE, .packages='randomForest') %dopar% {
			randomForest(x=this.x, y=this.y, ntree=ntree, importance=TRUE)
		}
	print(Sys.time()-start.time)
	start.time <- Sys.time()
	untreated.rf <- foreach(this.x=untreated.x, this.y=untreated.y, .combine=combine, .multicombine=TRUE, .packages='randomForest') %:%
		foreach(ntree=rep(100, 5), .combine=combine, .multicombine=TRUE, .packages='randomForest') %dopar% {
			randomForest(x=this.x, y=this.y, ntree=ntree, importance=TRUE)
		}
	print(Sys.time()-start.time)
	# Save merged forest
	print("Saving models...")
	saveRDS(treated.rf, file=paste(paste(opt$args[2], dataset.name, "_treated", sep=""), ".rds", sep=""))
	saveRDS(untreated.rf, file=paste(paste(opt$args[2], dataset.name, "_untreated", sep=""), ".rds", sep=""))
 }

files <- list.files(path=opt$args[1])
files.set <- splitbyset(files)
for (this.dataset in names(files.set)) {
	rforest(this.dataset, files.set[[this.dataset]])
}
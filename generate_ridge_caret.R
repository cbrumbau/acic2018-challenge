#!/usr/bin/env Rscript
#
# Rscript generate_ridge_caret.R --folds --include --merge imputations_folder output_folder
# This R script generates ridge linear regression models from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/21/2018

library("caret")
library("doMC")
library("optparse")
library("tools")

option_list <- list(
	make_option(c("-f", "--folds"), type="integer", default=5,
		help="number of folds to use for cross validation [default %default]", metavar="number"),
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific features to use for training the elasticnet [default %default]"),
	make_option(c("-m", "--merge"), type="logical", default=FALSE, 
		help="merge the imputation elasticnet models by data set and do not compute the models [default %default]")
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

ridge <-function(dataset.name, imputation.list) {
	print(paste("Processing ", dataset.name, sep=""))
	imputed.set <- list()
	for (file in imputation.list) {
		imputed.set[[length(imputed.set)+1]] <- read.csv(file=paste(opt$args[1], file, sep=""), header=TRUE, sep=",")
	}
	imputed.x <- list()
	imputed.y <- list()
	for (this.set in imputed.set) {
		imputed.x[[length(imputed.x)+1]] <- this.set[, !names(this.set) %in% c("sample_id", "z", "y")]
		if (nchar(opt$options$include[1]) > 0) {
			imputed.x[[length(imputed.x)]] <- this.set[, include]
		}
		imputed.y[[length(imputed.y)+1]] <- this.set[, c("y")]
	}
	train.control <- trainControl(method="cv", number=opt$options$folds[1], verboseIter=TRUE)
	print(paste("Generating ridge regression for", imputation.list, sep=" "))
	start.time <- Sys.time()
	en.list <- foreach(this.x=imputed.x, this.y=imputed.y, .inorder=TRUE, .packages='caret') %dopar% {
		train(x=this.x, y=this.y, trControl=train.control, method="foba")
	}
	print(Sys.time()-start.time)
	print("Saving models...")
	for (i in 1:length(en.list)) {
		saveRDS(en.list[[i]], file=paste(opt$args[2], tools::file_path_sans_ext(imputation.list[i]), ".rds", sep=""))
	}
}

if (opt$options$merge[1]) {
	print("TO BE COMPLETED")
} else {
	files <- list.files(path=opt$args[1])
	files.set <- splitbyset(files)
	for (this.dataset in names(files.set)) {
		ridge(this.dataset, files.set[[this.dataset]])
	}
}
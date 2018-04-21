#!/usr/bin/env Rscript
#
# Rscript generate_random_forests_h2o.R imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as h2o object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/15/2018

library("h2o")
library("optparse")
library("tools")
library("randomForest")

opt_parser <- OptionParser(usage = "%prog [options] imputations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

rforest <- function(filename) {
	print(paste("Processing ", filename, sep=""))
	this.set <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE, sep=",")
	train.h2o <- as.h2o(this.set[, !names(this.set) %in% c("sample_id", "z")])
	x.indep <- c(1:grep("^y$", colnames(train.h2o))-1)
	y.dep <- grep("^y$", colnames(train.h2o))
	result <- tryCatch({
		start.time <- Sys.time()
		this.rf <- h2o.randomForest(y=y.dep, x=x.indep, training_frame=train.h2o, ntrees=500)
		print(Sys.time()-start.time)
	}, warning = function(w) {
		print(paste("WARNING: ", w))
	}, error = function(e) {
		print(paste("ERROR: ", e))
	}, finally = {
		print("Saving model...")
		h2o.saveModel(object=this.rf, path=opt$args[2], force=TRUE)
	})
 }

localH2O <- h2o.init()
files <- list.files(path=opt$args[1])
invisible(lapply(files, rforest))
h2o.shutdown(prompt=FALSE)

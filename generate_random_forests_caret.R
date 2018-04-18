#!/usr/bin/env Rscript
#
# Rscript generate_random_forests_caret.R --merge imputations_folder output_folder
# This R script generates random forests from an imputations folder to an output folder as R object files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/14/2018

library("caret")
library("doMC")
library("optparse")
library("randomForest")
library("tools")

option_list <- list(
	make_option(c("-m", "--merge"), type="logical", default=FALSE, 
		help="merge the imputation random forest models by data set and do not compute the random forests [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] imputations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)
registerDoMC()

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
	# Perform training on first imputation, use trained mtry for remaining imputations
	trained.mtry <- NULL
	for (i in 1:length(imputation.list)) {
		this.set <- read.csv(file=paste(opt$args[1], imputation.list[i], sep=""), header=TRUE, sep=",")
		if (i == 1) {
			# Perform the k-fold cross validation
			print(paste("Processing ", imputation.list[i], sep=""))
			train.control <- trainControl(method="cv", number=10, verboseIter=TRUE)
			start.time <- Sys.time()
			rf.fit <- train(x=this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")], y=this.set[, c("y")], trControl=train.control, method="rf", allowParallel=TRUE)
			print(Sys.time()-start.time)
			trained.mtry <- rf.fit$bestTune$mtry
			print("Saving model...")
			saveRDS(rf.fit$finalModel, file=paste(paste(opt$args[2], tools::file_path_sans_ext(imputation.list[i]), sep=""), ".rds", sep=""))
		} else {
			# Generate remaining imputation models with trained mtry
			print(paste("Processing ", imputation.list[i], sep=""))
			start.time <- Sys.time()
			this.rf <- foreach(ntree=rep(100, 5), .combine=combine, .multicombine=TRUE, .packages='randomForest') %dopar% {
				randomForest(this.set[, !names(this.set) %in% c("X", "sample_id", "z", "y")], y=this.set[, c("y")], mtry=trained.mtryn, ntree=ntree)
			}
			print(Sys.time()-start.time)
			print("Saving model...")
			saveRDS(this.rf, file=paste(paste(opt$args[2], tools::file_path_sans_ext(imputation.list[i]), sep=""), ".rds", sep=""))
		}
	}
 }

if (opt$options$merge[1]) {
	files <- list.files(path=opt$args[2])
	# Categorize imputations belonging to each data set from the files
	files.set <- splitbyset(files)
	# Read in all the randomForest objects for each data set
	for (this.dataset in names(files.set)) {
		models.set = list()
		for (this.rds in files.set[[this.dataset]]) {
			models.set[[length(models.set)+1]] <- readRDS(paste(opt$args[2], this.rds, sep=""))
		}
		# Merge into one model and write this output
		print(paste("Merging random forest models for ", this.dataset))
		merged.rf <- do.call("combine", models.set)
		print("Saving merged model...")
		saveRDS(merged.rf, file=paste(opt$args[2], this.dataset, sep=""))
	}
} else {
	files <- list.files(path=opt$args[1])
	files.set <- splitbyset(files)
	for (this.dataset in names(files.set)) {
		rforest(this.dataset, files.set[[this.dataset]])
	}
}
#!/usr/bin/env Rscript
#
# Rscript generate_stepAIC_caret.R --folds --include input.csv output.rds
# This R script generates a linear regression model using stepwise Akaike information criterion (AIC) from an input.csv to an output.rds.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/18/2018

library("caret")
library("doMC")
library("optparse")

option_list <- list(
	make_option(c("-f", "--folds"), type="integer", default=5,
		help="number of folds to use for cross validation [default %default]", metavar="number"),
	make_option(c("-i", "--include"), type="character", default="", 
		help="file containing specific features to use for training the glm [default %default]")
)
opt_parser <- OptionParser(usage = "%prog [options] input.csv output.rds", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)
registerDoMC()

if (nchar(opt$options$include[1]) > 0) {
	include <- scan(opt$options$include[1], what=character())
}

print(paste("Processing ", opt$args[1], sep=""))
this.set <- read.csv(file=opt$args[1], header=TRUE, sep=",")
this.x <- this.set[, !names(this.set) %in% c("sample_id", "z", "y")]
if (nchar(opt$options$include[1]) > 0) {
	this.x <- this.x[, include]
}
this.y <- this.set[, c("y")]
train.control <- trainControl(method="cv", number=opt$options$folds[1], verboseIter=TRUE)
print("Generating linear model using stepwise AIC...")
start.time <- Sys.time()
this.glm <- train(x=this.x, y=this.y, trControl=train.control, method="glmStepAIC", allowParallel=TRUE)
print(Sys.time()-start.time)
print("Saving optimal model...")
saveRDS(this.glm, file=opt$args[2])
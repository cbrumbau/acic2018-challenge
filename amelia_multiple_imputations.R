#!/usr/bin/env Rscript
#
# Rscript amelia_multiple_imputations.R --number=number_of_imputations observations_folder output_folder
# This R script generates multiple imputations from an observations folder to an output folder as csv files.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/04/2018

library("optparse")
library("tools")
library("Amelia")

option_list <- list(
	make_option(c("-n", "--number"), type="integer", default=5, 
		help="number of imputations to generate [default %default]", metavar="number")
)
opt_parser <- OptionParser(usage = "%prog [options] observations_folder output_folder", option_list=option_list)
opt <- parse_args(opt_parser, positional_arguments=2)

mimput <- function(filename) {
	df <- read.csv(file=paste(opt$args[1], filename, sep=""), header=TRUE, sep=",")
	# from manual examination of warnings for colinearlity for these data sets
	exclude <- c("ufagecomb","f_forigin","f_clinest","f_apgar5","f_rf_pdiab","f_rf_gdiab","f_rf_phyper","f_rf_ghyper","f_rf_ppb","f_rf_ppo","f_rf_cesar","f_rf_ncesar","f_ob_cervic","f_ob_fail","f_ol_rupture","f_ol_precip","f_ol_prolong","f_ld_induct","f_ld_augment","f_ld_steroids","f_ld_antibio","f_ld_chorio","f_ld_mecon","f_ld_fintol","f_ld_anesth","f_md_present","f_md_route","f_md_trial","f_ab_vent","f_ab_vent6","f_ab_nicu","f_ab_surfac","f_ab_antibio","f_ab_seiz","f_ab_inj","f_ca_anen","f_ca_menin","f_ca_heart","f_ca_hernia","f_ca_ompha","f_ca_gastro","f_ca_limb","f_ca_cleftlp","f_ca_cleft","f_ca_downs","f_ca_chrom","f_ca_hypos","f_wtgain","f_mpcb","f_urf_diabetes","f_urf_chyper","f_urf_phyper","f_urf_eclamp","f_uob_induct","f_uld_meconium","f_uld_precip","f_uld_breech","f_u_forcep","f_u_vacuum","f_uca_anen","f_uca_spina","f_uca_omphalo","f_uca_cleftlp","f_uca_downs","rf_phyp","rf_ghyp","rf_eclam","ld_mecon","ca_anen","ca_menin","ca_ompha","ca_gastro","ca_cleft")
	a.out <- amelia(df[, !(names(df) %in% exclude)], m=opt$options$number[1], idvars=c("sample_id"), empri=0.01*nrow(df))
	write.amelia(obj=a.out, file.stem = paste(paste(opt$args[2], tools::file_path_sans_ext(filename), sep=""), "_", sep=""), quote=FALSE)
 }
 
files <- list.files(path=opt$args[1])
invisible(lapply(files, mimput))
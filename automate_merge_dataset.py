#!/usr/bin/env python3
#
# automate_merge_dataset.py covariate_matrix.csv observations_folder output_folder
# This Python script returns the merged factors from an observation folder to an output folder.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/03/2018

import argparse, os, sys
import merge_dataset

parser = argparse.ArgumentParser()
parser.add_argument('covariate', action='store', help='The covariate matrix as csv.')
parser.add_argument('observations_dir', action='store', help='The factual observations folder.')
parser.add_argument('output_dir', action='store', help='The output folder to write the merged files to.')
args = parser.parse_args()

# Get all files in the observations folder
observation_filenames = []
for (dirpath, dirnames, filenames) in os.walk(args.observations_dir):
    observation_filenames.extend(filenames)
    break
# Process the csv files found and merge with covariate matrix
for filename in observation_filenames:
	if os.path.splitext(filename)[1].lower() == ".csv":
		merge_dataset.merge_dataset(args.covariate, os.path.normpath(args.observations_dir + os.sep + filename), os.path.normpath(args.output_dir + os.sep + filename))

sys.exit(0)
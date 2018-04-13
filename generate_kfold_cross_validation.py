#!/usr/bin/env python3
#
# generate_kfold_cross_validation.py observations_folder output_folder
# This Python script generates data sets for k-fold cross validation from an observation folder to an output folder.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/13/2018

import argparse, csv, os, sys
import merge_dataset

parser = argparse.ArgumentParser()
parser.add_argument('observations_dir', action='store', help='The complete factual observations folder.')
parser.add_argument('output_dir', action='store', help='The output folder to write the merged files to.')
args = parser.parse_args()

def merge_csv(csv_files, output_csv):
	merge_list = list()
	for file in csv_files:
		this_csv = merge_dataset.read_csv(os.path.normpath(args.observations_dir + os.sep + file))
		if len(merge_list) == 0:
			# Read in first file with header
			merge_list.extend(this_csv)
		else:
			# Read in the rest of the files without header
			merge_list.extend(this_csv[1:])
	# Write out to file
	csv_file = open(os.path.normpath(args.output_dir + os.sep + output_csv), 'w', newline='')
	writer = csv.writer(csv_file, quoting=csv.QUOTE_MINIMAL)
	for line in merge_list:
		writer.writerow(line)
	csv_file.close()

# Get all files in the observations folder
observation_filenames = []
for (dirpath, dirnames, filenames) in os.walk(args.observations_dir):
    observation_filenames.extend(filenames)
    break

for filename in observation_filenames:
	if os.path.splitext(filename)[1].lower() == ".csv":
		# Leave this file out for testing, merge the rest
		print("Processing training set for testing on", filename, file=sys.stderr)
		merge_csv([f for f in observation_filenames if f != filename], filename)

sys.exit(0)
#!/usr/bin/env python3
#
# move_uncensored_files.py input_folder output_folder
# This Python script moves files that do not need to impute values from an input folder to an output folder.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/27/2018

import argparse, os, sys
import merge_dataset

parser = argparse.ArgumentParser()
parser.add_argument('input_dir', action='store', help='The folder containing files to check.')
parser.add_argument('output_dir', action='store', help='The output folder to move files to.')
args = parser.parse_args()

# Get all files in the input folder
input_filenames = []
for (dirpath, dirnames, filenames) in os.walk(args.input_dir):
    input_filenames.extend(filenames)
    break

# Check the files for any files lacking censored data
complete_files = list()
for filename in input_filenames:
	csv_list = merge_dataset.read_csv(os.path.normpath(args.input_dir + os.sep + filename))
	missing_value = False
	for row in csv_list[1:]:
		if "" in row:
			missing_value = True
	if not missing_value:
		complete_files.append(filename)

# Move to output
print("Moving files:\n" + "\n".join(complete_files))
for filename in complete_files:
	try:
		os.rename(os.path.normpath(args.input_dir + os.sep + filename), os.path.normpath(args.output_dir + os.sep + filename))
	except OSError as e:
		print(e, file=sys.stderr)
print("Done")

sys.exit(0)
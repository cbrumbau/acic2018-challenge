#!/usr/bin/env python3
#
# set_union.py input_folder output_file
# This Python script performs stepwise unions on sets from an input folder to an output file.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/20/2018

import argparse, os, sys

parser = argparse.ArgumentParser()
parser.add_argument('input_dir', action='store', help='The folder containing sets in text files.')
parser.add_argument('output_file', action='store', help='The output text file to write to.')
args = parser.parse_args()

def union_sets(set_files, output_txt):
	union_of_sets = set()
	for file in set_files:
		union_of_sets = union_of_sets.union(set(line.strip() for line in open(os.path.normpath(args.input_dir + os.sep + file))))
	# Write out to file
	out_file = open(output_txt, 'w', newline='\n')
	for item in union_of_sets:
		print(item, file=out_file)
	out_file.close()

# Get all files in the input folder
input_filenames = []
for (dirpath, dirnames, filenames) in os.walk(args.input_dir):
    input_filenames.extend(filenames)
    break

union_sets(input_filenames, args.output_file)

sys.exit(0)
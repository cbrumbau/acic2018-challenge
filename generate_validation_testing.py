#!/usr/bin/env python3
#
# generate_validation_testing.py --output=output_file.csv factual_observations.csv counterfactual_observations.csv
# This Python script fills in missing values from the factual observations with the truth from the counterfactual observations file and writes the output to stdout unless an output file is specified.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 04/13/2018

import csv
import merge_dataset

def merge_validation(factual, counterfactual, output=None):
	# Read in the observations and store in a list
	f_list = merge_dataset.read_csv(factual)

	# Read in the counterfactual observations and store in a list
	cf_list = merge_dataset.read_csv(counterfactual)

	# Fill missing values in the factual with the counterfactual
	z = 1
	y = 2
	y0 = 1
	y1 = 2
	# Write out header for the factual file
	if not output:
		print (*f_list[0], sep=",")
	else:
		csv_file = open(output, 'w', newline='')
		writer = csv.writer(csv_file, quoting=csv.QUOTE_MINIMAL)
		writer.writerow(f_list[0])
	# Fill in missing values with values from the counterfactual file
	for index, row in enumerate(f_list[1:]):
		if row[y] == "":
			if int(row[z]) == 0:
				row[y] = cf_list[index+1][y0]
			elif int(row[z]) == 1:
				row[y] = cf_list[index+1][y1]
		if not output:
			print (*row, sep=",")
		else:
			writer.writerow(row)
	if output:
		csv_file.close()


if __name__ == "__main__":
	import argparse, sys
	
	parser = argparse.ArgumentParser()
	parser.add_argument('factual', action='store', help='The factual observations as csv.')
	parser.add_argument('counterfactual', action='store', help='The counterfactual observations as csv.')
	parser.add_argument('-o', '--output', action='store', default=None, help='The file to write the merged file to. Default: None')
	args = parser.parse_args()
	
	merge_validation(args.factual, args.counterfactual, args.output)
	
	sys.exit(0)
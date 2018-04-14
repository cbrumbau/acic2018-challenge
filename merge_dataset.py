#!/usr/bin/env python3
#
# merge_dataset.py --output=output_file.csv covariate_matrix.csv observations.csv
# This Python script returns the merged factors with the observations to stdout unless an output file is specified.
#
# Chris Brumbaugh, cbrumbau@gmail.com, 03/30/2018

import csv

# Read in a csv file and return it as a list of rows
def read_csv(file):
	csv_list = []
	with open(file) as f:
		reader = csv.reader(f)
		try:
			for row in reader:
				csv_list.append(row)
		except csv.Error as e:
			sys.exit('file {}, line {}: {}'.format(file, reader.line_num, e))
	return csv_list

def merge_dataset(covariate, observations, output=None):
	# Read in the covariate matrix and store in a list
	covar_list = read_csv(covariate)

	# Read in the observations and store in a list
	obs_list = read_csv(observations)

	# Find the common field between the two files
	covar_header_set = set(covar_list[0])
	obs_header_set = set(obs_list[0])
	header_union = covar_header_set & obs_header_set
	if len(header_union) > 1:
		sys.exit('files contain multiple headers in common {}'.format(len(header_union)))
	covar_dict_key = header_union.pop()

	# Ensure that the common field is unique values in the covariate matrix to use as a dict key
	covar_key_index = covar_list[0].index(covar_dict_key)
	covar_key_set = set()
	for row in covar_list[1:]:
		covar_key_set.add(row[covar_key_index])
	if len(covar_list[1:]) != len(covar_key_set):
		sys.exit('covariate matrix contains non-unique key field {} for {}, {}'.format(covar_dict_key, len(covar_list[1:]),  len(covar_key_set)))

	# Use this field as the keys for the covariate matrix dict
	covar_dict = {}
	for row in covar_list[1:]:
		covar_dict[row[covar_key_index]] = row

	# Merge the covariate matrix information into the observations
	# Generate the new merged header
	obs_key_index = obs_list[0].index(covar_dict_key)
	new_obs_header = obs_list[0]
	del new_obs_header[obs_key_index]
	merge_header = covar_list[0]
	merge_header.extend(new_obs_header)
	if not output:
		print (*merge_header, sep=",")
	else:
		csv_file = open(output, 'w', newline='')
		writer = csv.writer(csv_file, quoting=csv.QUOTE_MINIMAL)
		writer.writerow(merge_header)
	# Generate the new merged rows
	for row in obs_list[1:]:
		this_row_key = row[obs_key_index]
		del row[obs_key_index]
		merge_row = covar_dict[this_row_key]
		merge_row.extend(row)
		if not output:
			print (*merge_row, sep=",")
		else:
			writer.writerow(merge_row)
	if output:
		csv_file.close()

if __name__ == "__main__":
	import argparse, sys
	
	parser = argparse.ArgumentParser()
	parser.add_argument('covariate', action='store', help='The covariate matrix as csv.')
	parser.add_argument('observations', action='store', help='The factual observations as csv.')
	parser.add_argument('-o', '--output', action='store', default=None, help='The file to write the merged file to. Default: None')
	args = parser.parse_args()
	
	merge_dataset(args.covariate, args.observations, args.output)
	
	sys.exit(0)
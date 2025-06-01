__author__ = "Janice Darling"
import csv



with open("cd101.csv", 'rb') as fi:
	reader = csv.reader(fi)
	with open("matrix_file.txt", "w") as mf:
		for row in reader:
			row = str(row).split('[')[1].split(']')[0].replace("'", "").replace(",", "")
			mf.write(row)
			mf.write('\n')
		
		


		

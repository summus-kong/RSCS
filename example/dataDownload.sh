#!/bin/bash

## Test data from GSE70605 and GSE83581

# check fastq-dump

which fastq-dump > /dev/null 2>$1
if [[ $? -ne 0 ]]
then
	echo "Funciton fastq-dump appears NOT to be found"
	echo "Please install SRA Toolkit or use other toolkits"
	exit 1
fi

# check and creat folder ./rnaseq and ./srna-seq

if [[ -d ./rnaseq ]]
then
	echo "Folder ./rnaseq already exists.\t"
	read -t 10 -p "Overwrite ./rnaseq or not[yes(y) | no(n)]: " name
	case $name in
		yes | y) rm -rf ./rnaseq;mkdir ./rnaseq;;
		no | n) echo "";;
	esac
else
	mkdir ./rnaseq
fi

if [[ -d ./srnaseq ]]
then
        echo "Folder ./srnaseq already exists.\t"
        read -t 10 -p "Overwrite ./srnaseq or not[yes(y) | no(n)]: " name
        case $name in
                yes | y) rm -rf ./srnaseq;mkdir ./srnaseq;;
                no | n) echo "";;
        esac
else
        mkdir ./srnaseq
fi

# download test data
fastq-dump --gzip --split-3 SRR2089603 -O ./rnaseq
fastq-dump --gzip --split-3 SRR1538552 -O ./srnaseq

## End

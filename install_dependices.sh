#!/bin/bash

## RSCS
## This script aims in installing most of the dependices of the RSCS pipeline.

echo "Prepare the RSCS essential environment ..."
##############check standard tools###############

# make
which make > /dev/null
if [[ $? -ne 0 ]]
then
	echo -e "Can not proceed without make, please install and re-run"
	exit 1
fi

# tar
which tar > /dev/null
if [[ $? -ne 0 ]]
then
        echo -e "Can not proceed without tar, please install and re-run"
        exit 1
fi

# unzip
which unzip > /dev/null
if [[ $? -ne 0 ]]
then
	echo -e "Can not proceed without unzip, please install and re-run"
	exit 1
fi

# java
which java > /dev/null
if [[ $? -ne 0 ]]
then
	echo -e "Can not proceed without java, please install and re-run"
	exit 1
fi


# python
which python > /dev/null
if [[ $? -ne 0 ]]
then
        echo -e "Can not proceed without python, please install and re-run"
        exit 1
else
	version=`python --version 2>&1 | cut -d" " -f2 | cut -d"." -f1`
    	if [ $version == "3" ]
	then
		exit 0
	fi
    	if [[ $? -ne 0 ]]
    	then
		echo -e "Python v3 or higher is needed [$version detected]"
		exit 1
    	fi
fi

# check OS (Unix/Linux or Mac)
os=`uname`

# get the right download program
if [[ "$os" -eq "Darwin" ]]
then
	# use curl download 
	get="curl -L -o"
else
	# use wget download
	get="wget --no-check-certificate -O"
fi

# check bioinformatics software
which samtools > /dev/null && which fastqc > /dev/null && which trim_galore > /dev/null && which hisat2 > /dev/null
if [[ $? -eq 0 ]]
then
	echo "The RSCS environment appears to be already done"
else
	echo "Create folder to install bioinformatics software"
	mkdir ~/rscs_biosoft
	softpath=$(echo `cd ~/rscs_biosoft;pwd`)
fi

###############FastQC###############

installed=0
which fastqc > /dev/null
if [[ $? -eq 0 ]]
then
	echo "FatQC has been installed"
	installed=1
fi

if [[ $installed -eq 0 ]]
then
	echo "Installing FastQC ..."
	$get fastqc_v0.11.9.zip https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
	unzip fastqc_v0.11.9.zip
	chmod u+x FastQC/fastqc
	mv FastQC ~/rscs_biosoft;mv fastqc_v0.11.9.zip ~/rscs_biosoft
	echo "export PATH=$softpath/FastQC/:$PATH" >> ~/.bashrc
	. ~/.bashrc
	installed=0
fi

# test fastqc
if [[ installed -eq 0 ]]
then
	fastqc --version > /dev/null 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "FatQC appears to be installed successfully"
	else
		echo "FastQC NOT to be installed successfully"
	fi
fi

###############SAMtools###############

installed=0
which samtools > /dev/null
if [[ $? -eq 0 ]]
then
	echo "SAMtools has been installed"
	installed=1
fi

if [[ $installed -eq 0 ]]
then
	echo "Installing SAMtools ..."
	$get samtools-1.12.tar.bz2 https://sourceforge.net/projects/samtools/files/samtools/1.12/samtools-1.12.tar.bz2/download
	tar -xvjpf samtools-1.12.tar.bz2
	cd samtools-1.12
	make
	cd ..
	mv samtools-1.12 ~/rscs_biosoft;mv samtools-1.12.tar.bz2 ~/rscs_biosoft
	echo "export PATH=$softpath/samtools-1.12/:$PATH" >> ~/.bashrc
	. ~/.bashrc
	installed=0
fi

# test samtools
if [[ $installed -eq 0 ]]
then
	samtools --version > /dev/null 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "SAMtools appears to be installed successfully"
	else
		echo "SAMtools NOT to be installed successfully"
	fi
fi

###############Trim Galore###############

installed=0
which trim_galore > /dev/null
if [[ $? -eq 0 ]]
then
	echo "Trim Galore has been installed"
	installed=1
fi

if [[ $installed -eq 0 ]]
then
	echo "Installing Trim Galore ..."
	$get trim_galore-0.6.6.tar.gz https://github.com/FelixKrueger/TrimGalore/archive/0.6.6.tar.gz
	tar xvzf trim_galore-0.6.6.tar.gz
	mv TrimGalore-0.6.6 ~/rscs_biosoft;mv trim_galore-0.6.6.tar.gz ~/rscs_biosoft
	echo "export PATH=$softpath/TrimGalore-0.6.6/:$PATH" >> ~/.bashrc
	. ~/.bashrc
	installed=0
fi

# test trim_galore
if [[ $installed -eq 0 ]]
then
	trim_galore --version > /dev/null 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "Trim Galore appears to be installed successfully"
	else
		echo "Trim Galore NOT to be installed successfully"
	fi
fi

###############HISAT2###############

installed=0
which hisat2 > /dev/null 
if [[ $? -eq 0 ]]
then
	echo "HISAT2 has been installed"
	installed=1
fi

if [[ $installed -eq 0 ]]
then
	echo "Installing HISAT2 ..."
	$get hisat2-2.2.1.zip https://cloud.biohpc.swmed.edu/index.php/s/oTtGWbWjaxsQ2Ho/download
	unzip hisat2-2.2.1.zip
	mv hisat2-2.2.1/ ~/rscs_biosoft;mv hisat2-2.2.1.zip ~/rscs_biosoft
	echo "export PATH=$softpath/hisat2-2.2.1/:$PATH" >> ~/.bashrc
	. ~/.bashrc
	installed=0
fi

if [[ $installed -eq 0 ]]
then
	hisat2 --version > /dev/null 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "HISAT2 appears to be installed successfully"
	else
		echo "HISAT2 NOT to be installed successfully"
	fi
fi


echo 
## End of procession ##


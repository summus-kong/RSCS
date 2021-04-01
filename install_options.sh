#!/bin/bash

## RSCS
## This script aims in installing most of the options of the RSCS pipeline.

echo "Prepare the RSCS optional environment ..."
# check OS (Unix/Linux)
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

# check the installation path

if [[ ! -d ~/rscs_biosoft ]]
then
	mkdir ~/rscs_biosoft
fi

###############Aspera###############

installed=0
which ascp > /dev/null
if [[ $? -eq 0 ]]
then
        echo "Aspera has been installed"
        installed=1
fi

if [[ $installed -eq 0 ]]
then
	read -t 10 -p "Aspera for download sequencing data.install aspera or not?[yes(y) | no(n)]: "answer
	case $answer in
		yes | y)
		  echo "Installing Aspera ..."
       		  $get aspera-3.11.1.58.tar.gz https://d3gcli72yxqn2z.cloudfront.net/connect_latest/v4/bin/ibm-aspera-connect-3.11.1.58-linux-g2.12-64.tar.gz
        	  mv aspera-3.11.1.58.tar.gz ~/rscs_biosoft 
		  tar zxvf ~/rscs_biosoft/aspera-3.11.1.58.tar.gz
       		  bash ~/rscs_biosoft/ibm-aspera-connect-3.11.1.58-linux-g2.12-64.sh
        	  echo "export PATH=~/.aspera/connect/bin:$PATH" >> ~/.bashrc
        	  . ~/.bashrc
        	  installed=0;;
		no | n) installed=0;break;;
  esac
fi

# test aspera
if [[ $installed -eq 0 ]]
then
        ascp --version > /dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
                echo "Aspera appears to be installed successfully"
        else
                echo "Aspera NOT to be installed successfully"
        fi
fi

###############SRA Toolkit###############

which fastq-dump > /dev/null
if [[ $? -eq 0 ]]
then
        echo "SRA Toolkit has been installed"
else
	echo "SRA Toolkit fastq-dump function for downloading SRA fastq files."
	echo "If you use funciton get_Fastq_files, please install it."
fi

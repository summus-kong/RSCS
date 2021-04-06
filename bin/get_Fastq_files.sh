#!/bin/bash

## Download Fastq data using wget or aspera or fastq-dump

# funciton for displaying help document

usage()
{
gs=$(basename $0 .sh)
cat << EOF

Description: Download Fastq data by SRA Run accession begin with "SRR".

Usage: $gs -i <accession file> -o <outputdir> -e [-d -t -h]

Options:
	-i Input SRA Run accession begin with "SRR". Entries can be comma-delimited or individual
	-o Output dirctory[Default: current dirctory]
	-d Download data using wget or aspera. When the parameter is wget, use wget to download data;
	   when the parameter is aspera, use  to download data;when the parameter is fqdump, use 
           fastq-dump to download data[Default: wget]
	-e single end or paired end sequencing.Two values: [single | paired] [Default: paired]
	-t Number of threads[INT]
	-h Show this message

EOF
}

if [[ $# -lt 1 ]]
then
	usage;exit
fi

# define input arguments

input=
outdir=
d=
single_or_paired=
t=
GETOPT_ARGS=`getopt -o i:o:d:e:t:h -- "$@"`
eval set -- "$GETOPT_ARGS"
while [[ -n "$1" ]]
do
	case "$1" in 
	-h) usage
	    exit;;
	-i) input=$2
	    shift;;
	-o) outdir=$2
	    shift;;
	-d) d=$2
	    shift;;
	-e) single_or_paired=$2
	    shift;;
	-t) t=$2
	    shift;;
	--) shift;break;;
	*)  usage;break;;
	esac
	shift
done

# default settings

if [[ -z "$outdir" ]]
then
	outdir=./
fi

if [[ -z "$d" ]]
then
	d="wget"
fi

if [[ -z "$t" ]]
then
	t=1
fi

if [[ -z "$single_or_paired" ]]
then
	single_or_paired="paired"
fi

# define global arguments

Njobmax=`grep 'processor' /proc/cpuinfo | sort -u | wc -l`
Njob=`wc -l $input | cut -d " " -f 1`

if [[ $t -gt $Njobmax ]]
then
        t=$Njobmax
fi

if [[ $Njob -lt $t ]]
then
        t=$Njob
fi

# define function for tmp_fifo

tmp(){
tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile
exec 6<>$tmp_fifofile
rm $tmp_fifofile

for((i=0;i<${t};i++));
do
    echo
done >&6
}

###############download data using wget##############

# define wget_single and wget_paired function

wget_single(){
for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
                wget -c -P ${outdir}  ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${first_six}/00${last}/$i/${i}.fastq.gz
                echo >&6
        } &
done
wait
exec 6>&-
}

wget_paired(){
for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
                f1='_1.fastq.gz'
                f2='_2.fastq.gz'
                get="wget -c -P ${outdir}  ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${first_six}/00${last}/$i/${i}"
                $get$f1
                $get$f2
                echo >&6
        } &
done
wait
exec 6>&-
}

get_wFq()
{
# function for downloading Fastq data using wget
which wget > /dev/null
if [[ $? -ne 0 ]]
then
	echo "wget NOT to be found"
	exit 1
fi

tmp

case $single_or_paired in
	single) wget_single;;
	paired) wget_paired;;
esac

## End ##
}

###############download using aspera##############

# define ascp_single and ascp_paired function

ascp_single(){
for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
                ascp -QT -l 300m -k 1 -P33001 -i $1 era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/\
                        ${first_six}/00${last}/$i/${i}.fastq.gz $outdir
                echo >&6
        } &
done
wait
exec 6>&-
}

ascp_paired(){
for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
		f1="_1.fastq.gz"
		f2="_2.fastq.gz"
                ap="ascp -QT -l 300m -k 1 -P33001 -i $1 era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/${first_six}/00${last}/$i/${i}"
		$ap$f1 $output
		$ap$f2 $output
                echo >&6
        } &
done
wait
exec 6>&-
}

get_aFq()
{
# function for downloading SRA data using aspera
which ascp > /dev/null
if [ $? -ne 0 ]
then
	echo "aspera NOT to be found"
	exit 1
fi

webid=`find ~ -name asperaweb_id_dsa.openssh | sed -n "1p"`
tmp

case $single_or_paired in
	single) ascp_single ${webid};;
	paired) ascp_paired ${webid};;
esac

## End ##
}

##############fastq-dump###############

get_dFq(){
# function for downloading SRA data using wget
which fastq-dump > /dev/null
if [[ $? -ne 0 ]]
then
        echo "fastq-dump NOT to be found"
        exit 1
fi

tmp

for i in `cat $input`
do
        read -u6
        {
                fastq-dump --gzip --split-3 $i -O $outdir
                echo >&6
        } &
done
wait
exec 6>&-
## End ##
}
##############run###############

if [[ -n "$d" ]]
then

	case "$d" in
		wget) get_wFq;exit;;
		aspera) get_aFq;exit;;
		fqdump) get_dFq;exit;;
	esac
fi

echo ;
## End ##


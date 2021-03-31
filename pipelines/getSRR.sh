#!/bin/bash

## Download SRA data using wget or aspera

# funciton for displaying help document

usage()
{
gs=$(basename $0 .sh)
cat << EOF

Description: Download SRA data by SRA Run accession begin with "SRR".

Usage: $gs -i <accession file> -o <outputdir> [-d -t -h]

Options:
	-i Input SRA Run accession begin with "SRR". Entries can be comma-delimited or individual
	-o Output dirctory[Default: current dirctory]
	-d Download data using wget or aspera. When the parameter is wget, use wget to download data;
	   when the parameter is aspera, use  to download data[Default: wget]
	-t Number of threads[INT]
	-h Show this message

EOF
}

if [[ $# -lt 1 ]]
then
	usage;exit 1
fi

# define input arguments

input=
outdir=
d=
t=
GETOPT_ARGS=`getopt -o i:o:d:t:h -- "$@"`
eval set -- "$GETOPT_ARGS"
while [[ -n "$1" ]]
do
	case "$1" in 
	-h) usage
	    exit 1;;
	-i) input=$2
	    shift;;
	-o) outdir=$2
	    shift;;
	-d) d=$2
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

###############download using wget##############

get_wSRR()
{
# function for downloading SRA data using wget
which wget > /dev/null
if [[ $? -ne 0 ]]
then
	echo "wget NOT to be found"
	exit 1
fi

tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile
exec 6<>$tmp_fifofile
rm $tmp_fifofile

for((i=0;i<${t};i++));
do
    echo
done >&6

for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
                out=`echo $i.sra`
        	wget -c -P ${outdir} -O ${out} ftp://ftp.sra.ebi.ac.uk/vol1/srr/${first_six}/00${last}/$i
                echo >&6
        } &
done
wait
exec 6>&-
## End ##
}

###############download using aspera##############

get_aSRR()
{
# function for downloading SRA data using aspera
which ascp > /dev/null
if [ $? -ne 0 ]
then
	echo "aspera NOT to be found"
	exit 1
fi

webid=`find ~ -name asperaweb_id_dsa.openssh | sed -n "1p"`
tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile
exec 6<>$tmp_fifofile
rm $tmp_fifofile

for((i=0;i<${t};i++));
do
    echo
done >&6

for i in `cat $input`
do
        read -u6
        {
                first_six=${i: 0:6}
                last=${i: -1}
		out=`echo $i.sra`
                ascp -QT -l 300m -k 1 -P33001 -i ${webid} era-fasp@fasp.sra.ebi.ac.uk:/vol1/srr/${first_six}/00${last}/$i \
			$outdir
		if [ -s $i ] 
		then
			mv $i $out
		fi
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
		wget) get_wSRR;exit 1;;
		aspera) get_aSRR;exit 1;;
	esac
fi

echo ;
## End ##


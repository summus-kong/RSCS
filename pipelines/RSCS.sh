#!/bin/bash
# set -e
# set -u
# set -o pipefail
##
## Description: 
## 	      RSCS:RNA-seq and small RNA-seq combined strategy.
##	      This is a newly cpmputational pipeline to perform transcriptome annotation in a wide variety of mammalian samples. 
##
## Confirm you hvae installed fastqc,multiqc,trim_galore,hisat2,samtools
## Confrim your fastq file have pre-processed

# function for help output
usage()
{
sc=$(basename $0 .sh)
cat << EOF

Description: RSCS:RNA-seq and small RNA-seq combined strategy, 
		  a newly cpmputational pipeline to predict mouse transcripts.

usage: $sc <ARGUMENTS> [OPTIONS]

ARGUMENTS:
	-r --rnaseq_dir          RNA-seq dirctory,file format in this dirctory

        -s --srnaseq_dir         Small RNA-seq dirctory,file format in this dirctory

        -e --reference           The basename of the index for the reference genome. The basename is the name of any of the 
				 index files up to but not including the final .1.ht2 / etc. hisat2 looks for the specified  
				 index first in the current directory, then in the directory specified in the HISAT2_INDEX  
				 environment variable
	
	--single_or_pairedr	 Logical value of RNA-seq[TRUE or FALSE]


	--single_or_paireds	 Logical value of Small RNA-seq[TRUE or FALSE]

	-m --meta_data           Merge bam meta-data file,which is tab separate. file format:
                                                                                                sample1         sample2     
                                                                                                SRR2089677      SRR1200367    
                                                                                                SRR1005345      SRR1234123    

        -o --outputdir           Output dirctory
OPTIONS:
        -h --help                Show this message

	-p --threads INT	 Number of input/output compression threads to use in addition to main thread. Default[1]

	-k --kmer INT            It searches for at most <int> distinct, primary alignments for each read. Default[5]

EOF
}


if [ "$#" -lt 1 ]
then
        usage
	exit 0
fi

# define input arguments 
rnaseq_dir=
srnaseq_dir=
ref=
single_or_pairedr=
single_or_paireds=
p=
k=
meta=
outputdir=
name_r="RNA_seq"
name_s="small_RNA_seq"

GETOPT_ARGS=`getopt -o hr:s:e:p:k:m:o: -al help,rnaseq_dir:,srnaseq_dir:,reference:,threads:,kmer:,meta_data:,outputdir:,single_or_pairedr:,single_or_paireds:, -- "$@"`
eval set -- "$GETOPT_ARGS"
while [ -n $1 ] 
do
	case $1 in
		-h | --help) 
			usage
			exit 1;;

		-r | --rnaseq_dir) 
			rnaseq_dir=$2
			shift 2;;

		-s | --srnaseq_dir) 
			srnaseq_dir=$2
			shift 2;;

		--single_or_pairedr)
			single_or_pairedr=$2
			shift 2;;

		--single_or_paireds)
			single_or_paireds=$2
			shift 2;;

		-e | --reference)
			ref=$2
			shift 2;;

		-p | --threads)
			p=$2
			shift 2;;

		-k | --kmer)
			k=$2
			shift 2;;

		-m | --meta_data)
			meta=$2
			shift 2;;

		-o | --outputdir) 
			outputdir=$2
			shift 2;;
		--) 
			shift 2
			break;;
		*) 
			usage
			break;;
	esac
done

# default settings
if [ -n "$p" ]
then 
	echo ""
else
	p=1
fi

if [ -n "$k" ]
then
	echo ""
else
	k=5
fi

# get absolute path
rnaseq_dir=$(echo `cd $rnaseq_dir; pwd`)
srnaseq_dir=$(echo `cd $srnaseq_dir; pwd`)
outputdir=$(echo `cd $outputdir; pwd`)
refdir=$(dirname $ref)
refname=$(basename $ref)
refdir=$(echo `cd $refdir;pwd`)

# print critical arguments
echo "======================================"
echo -e "your specific parameters:\n"
echo -e "RNA-seq_dir = $rnaseq_dir\n"
echo -e "Small RNA-seq_dir = $srnaseq_dir\n"
echo -e "reference genome = $ref\n"
echo -e "output_dir = $outputdir\n"
echo -e "k = $k\n"
echo "======================================"

# change path format
if [[ $rnaseq_dir = */ ]]
then
	rnaseq_dir=${rnaseq_dir%?}
fi

if [[ $srnaseq_dir = */ ]]
then
        srnaseq_dir=${srnaseq_dir%?}
fi

if [[ $outputdir = */ ]]
then
        outputdir=${outputdir%?}
fi

# create dirctory needed
dir=`pwd`
echo "check if the folder exists, or create a folder if it doesn't"

mkd()
{
if [ $# == 1 ] 
then 
	if [ -e $outputdir/$1 -a -d $outputdir/$1 ]
	then
        	echo "dirctory $outputdir/$1 have existed"
	else
        	echo "create dirctory $outputdir/$1"
        	mkdir $outputdir/$1
	fi
fi
}


mkd clean_out
mkd bam_out
mkd merge_bam_out

# define path for result output
dir_co=$outputdir/clean_out
dir_b=$outputdir/bam_out
dir_m=$outputdir/merge_bam_out
echo " "

# function for checking fastq file suffix
suff()
{
# get file suffix
suffix=
ls $1/*fastq >/dev/null 2>&1
if [[ $? -eq 0 ]]
then
        suffix="fastq"
fi

ls $1/*fq >/dev/null 2>&1
if [[ $? -eq 0 ]]
then
        suffix="fq"
fi

ls $1/*fastq.gz >/dev/null 2>&1
if [[ $? -eq 0 ]]
then
        suffix="fastq.gz"
fi

ls $1/*fq.gz >/dev/null 2>&1if [[ $? -eq 0 ]]

then
        suffix="fq.gz"
fi

echo $suffix
}

####################################################
# FastQC
####################################################

fastqc()
{
suffix=$(suff $1)
if [ ! -e $1/fastqc ] && [ ! -d $1/fastqc ]
then
	mkdri $1/fastqc
fi

for i in `ls $1/*$suffix`
do
	fastqc $i -o $1/fastqc -t $p
done
multiqc $1/fastqc -o $1/fastqc
}


fastqc $rnaseq_dir
fastqc $srnaseq_dir

####################################################
# Trim Adapter
####################################################

trim_rs()
{
## RNA-seq
# create RNA-seq output dirctory
cd $dir_co
if [ -e rna ] && [ -d rna ]
then
        echo "$dir_co/rna have existed"
else
        echo "create dirctory $dir_co/rna"
        mkdir rna
fi

cd $dir

suffix=$(suff $rnaseq_dir)
# trim RNA-seq
case $single_or_pairedr in
	TRUE | T)
		 cat << EOF
####################################################
        This is paired-end $name_r sequencing
        Then,starting process sequencing reads
        Here use TrimGalore
        processing...
####################################################
EOF
		paste <(ls $rnaseq_dir/*1.$suffix) <(ls $rnaseq_dir/*2.$suffix) > rna.config
        	cat rna.config | while read id
        	do
                	arr=$id
                	fq1=${arr[0]}
                	fq2=${arr[1]}
                	trim_galore --paired $fq1 $fq2 -o $dir_co/rna
       		done;;
	FALSE | F)
		cat << EOF
####################################################
        This is single-end $name_r sequencing
        Then,starting process sequencing reads
        Here use TrimGalore
        processing...
####################################################

EOF
        	ls $rnaseq_dir/*$suffix > rna.config
        	for id in `cat srna.config`
        	do
                	trim_galore $id -o $dir_co/srna
        	done;;
esac
if [ -f "rna.config" ]
then
	rm rna.config
fi
}


trim_srs()
{
## small RNA-seq
# create small RNA-seq output dirctory
cd $dir_co
if [ -e srna ] && [ -d srna ]
then
        echo "$dir_co/srna have existed"
else
        echo "create dirctory $dir_co/srna"
        mkdir srna
fi

cd $dir

suffix=$(suff $srnaseq_dir)
# trim small RNA-seq
case $single_or_paireds in
	TRUE | T)
		cat << EOF
#####################################################
        This is paired-end $name_s sequencing
        Then,starting process sequencing reads
        Here use TrimGalore
        processing...
#####################################################

EOF
        	paste <(ls $srnaseq_dir/*1.$suffix) <(ls $srnaseq_dir/*2.$suffix) > srna.config
        	cat rna.config | while read id
        	do
                	arr=$id
                	fq1=${arr[0]}
                	fq2=${arr[1]}
                	trim_galore --paired $fq1 $fq2  --small_rna --length 18 -o $dir_co/rna
        	done;;
	FALSE | F)
		cat << EOF
#####################################################
        This is single-end $name_s sequencing
        Then,starting process sequencing reads
        Here use TrimGalore
        processing...
#####################################################

EOF
        	ls $srnaseq_dir/*$suffix > srna.config
        	for id in `cat srna.config`
        	do
                	trim_galore $id  --small_rna --length 18 -o $dir_co/srna
     		done;;
esac
if [ -f "srna.config" ]
then
	rm srna.config
fi
}

# perform trim adapter
if [ -n "$outputdir" ]
then
        if [ -n "$rnaseq_dir" ]
        then
                trim_rs
        else
                echo -n ""
        fi
	
        if [ -n "$srnaseq_dir" ]
        then
                trim_srs
        else
                echo -n ""
        fi
fi

####################################################
# Align to genome 
####################################################

aligndir()
{
a=$(pwd)
ad=${a##*/}
od=
if [ $ad == "rna" ]
then
	od=rna
elif [ $ad == "srna" ]
then
	od=srna
fi
}

# check hisat2 index 
ls $refdir/*ht2 >/dev/null 2>&1
if [[ $? -ne 0 ]]
then
	hisat2-build $refdir/$refname $refdir/genome
fi

align()
{
# align to genome by hisat2
suffix=$(suff $1)
case $2 in
	TRUE | T)
		cat << EOF
####################################################
        This is paired-end RNA-seq sequencing
        Then,starting process align to genome
        Here use HISAT2
        processing...
####################################################
EOF
		paste <(ls *$suffix | cut -d"_" -f 1 |sort | uniq) <(ls *_1.$suffix) <(ls *_2.$suffix) > his.config
		cat his.config|while read id
		do
			arr=(${id})
			sample=${arr[0]}
			fq1=${arr[1]}
			fq2=${arr[2]}
			echo $sample $fq1 $fq2
			hisat2 -p $p -k $k --dta -x $(dirname $ref)/genome -1 $fq1 -2 $fq2 -S $dir_b/$od/$sample.sam
		done
		ls $dir_b/$od/*.sam | while read id
		do
			samtools view -b -F 4 -@ $p $id | samtools sort -@ 4 -O BAM - > $dir_b/$od/$(basename -s .sam $id).bam
		done;;
	FALSE | F)
	 	cat << EOF
####################################################
        This is single-end RNA-seq sequencing
        Then,starting process align to genome
        Here use HISAT2
        processing...
####################################################
EOF
		paste <(ls *$suffix | cut -d"_" -f 1 | sort | uniq) <(ls *$suffix) > his.config
		cat his.config | while read id
		do
			arr=(${id})
			sample=${arr[0]}
			fq=${arr[1]}
			echo $sample $fq
			hisat2 -p $p -x $(dirname $ref)/genome --dta -k $k -U $fq -S $dir_b/$od/$sample.sam
		done
		ls $dir_b/$od/*sam | while read id
        	do
                	samtools view -b -F 4 -@ $p $id | samtools sort -@ 4 -O BAM - > $dir_b/$od/$(basename -s .sam $id).bam
        	done;;
esac
if [ -f "his.config" ]
then
	rm his.config
fi
}

his_rs_sam2bam()
{
# check if the folder exists
# if folders and files exist, start to process rna-seq hisat2 alignment
cd $dir_b
if [ -e ./rna ] && [ -d ./rna ]
then
        echo "$dir_b/rna have existed"
else
        echo "create dirctory $dir_b/rna"
        mkdir rna
fi
cd $dir
suffix=$(suff $dir_co/rna)
ls $dir_co/rna/*$suffix >/dev/null 2>&1
if [[ $? -eq 0 ]]
then
	cd $dir_co/rna
	aligndir
	align . $single_or_pairedr
	cd $dir
else
	echo "dirctory $dir_co/rna is not exist or file format in this dir is not correct"
fi
}


his_srs_sam2bam()
{
# check if the folder exists
# if folders and files exist, start to process hisat2
cd $dir_b
if [ -e ./srna ] && [ -d ./srna ]
then
        echo "$dir_b/srna have existed"
else
        echo "create dirctory $dir_b/srna"
        mkdir srna
fi

cd $dir
suffix=$(suff $dir_co/srna)
ls $dir_co/srna/*$suffix >/dev/null 2>&1
if [[ $? -eq 0 ]]
then
        cd $dir_co/srna
	echo "small RNA-seq alignment"
        aligndir
	align . $single_or_paireds
	cd $dir
else
        echo "dirctory $dir_co/srna is not exist or :file format in this dir is not correct"
fi
}

# perform hisat2 and samtools view
if [ -n "$ref" ] && [ -n "$outputdir" ] 
then
	his_rs_sam2bam
	his_srs_sam2bam
else
	echo -n ""
fi

####################################################
# merge bam  
####################################################

merge_bam_pre()
{
ls $dir_b/rna/*bam >/dev/null 2>&1 && ls $dir_b/srna/*bam >/dev/null 2>&1
if [[ $? -eq 0 ]] 
then
	if [ ! -e $dir_m/total ] && [ ! -d $dir_m/total ]
	then
		mkdir $dir_m/total
	fi
	
	ls $dir_b/rna/*bam | while read id
	do
		cp -f $id $dir_m/total/$(basename $id ".bam")
	done
	
	ls $dir_b/srna/*bam | while read id
        do
                cp -f $id $dir_m/total/$(basename $id ".bam")
        done
fi
}

# perform bam merge
if [ -n "$meta" ] && [ -n "$outputdir" ]
then
	merge_bam_pre
	if [[ $? -eq 0 ]]
	then
		a=($(cat $meta | head -n 1))
		colnum=${#a[@]}
        	awk 'NR>1{print $0}' $meta > file
    	    	for i in `seq 1 $colnum`
        	do
			bam=$(cut -f $i file | tr -s '\n' ' ')
			bam_list=$(echo $bam|awk '{for(i=1;i<=NF;i++){printf "'$dir_m'""/total/"$i" "}{print ""}}')
			echo "$bam_list"
                	samtools merge -f $dir_m/${a[$i-1]}.merged.bam $bam_list
        	done
		if [ $? == 0 ] 
		then
			rm file
		fi
		cd $dir
	fi
	if [ -e $dir_m/total ] && [ -d $dir_m/total ]
	then
		rm -r $dir_m/total
	fi
fi

echo 
## End

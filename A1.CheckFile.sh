##########################################################################
# File Name: A1.CheckFile.sh
# Author: Instant-Eternity
# mail: hunterfirstone@i.smu.edu.cn
# Created Time: Thu 03 Jun 2021 11:34:14 AM CST
#########################################################################
#!/usr/bin/bash
for file in A1.CheckFile.sh A2.SplitSample.sh A3.MakeSample.sh A4.Qiime2Upstream.sh A5.Qiime2Downstream.sh A6.Aldex2.sh A7.Pircrust2.sh A8.Lefse.sh A9.Qiime2R.R Run.sh Cut_ReverseBarcode.py
do
	if [ ! -f "${file}" ];then
		echo -e "Fatal Error: program file ${file} is missing.";
		exit 1;
	fi
done

DataFile_error="The data file input is incomplete or the data file does not meet the analysis requirements."

DataFile_num=`ls -l $PWD/*.clean.fq.gz | grep "^-" | wc -l`

if [ ${DataFile_num} == 2 ];then
	DataFile_1=`ls $PWD/*.clean.fq.gz|grep 1.clean.fq.gz`;
	DataFile_2=`ls $PWD/*.clean.fq.gz|grep 2.clean.fq.gz`;

	mv ${DataFile_1} 1.clean.fq.gz;
	mv ${DataFile_2} 2.clean.fq.gz;
else
	echo ${DataFile_error};
	exit 1;
fi

sample=args

for file in 1.clean.fq.gz 2.clean.fq.gz barcode.txt metadata_${sample}.txt
do
	if [ ! -f "${file}" ];then
		echo -e "Data Error: ${file} file is missing.";
		exit 1;
	else
		echo -e "${file} file is checked."
	fi
done

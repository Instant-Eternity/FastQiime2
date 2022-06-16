##########################################################################
# File Name: A2.SplitSample.sh
# Author: Instant-Eternity
# mail: hunterfirstone@i.smu.edu.cn
# Created Time: Thu 03 Jun 2021 11:34:14 AM CST
#########################################################################
#!/usr/bin/bash
sample=test

cp sample.list sample.tmp
sed -i '$d' sample.tmp

if [ ! -f "sample_${sample}.txt" ];then
	echo -e "sample_${sample}.txt is already exists, will be overwritten.";
	rm sample_${sample}.txt;
fi

echo -e "id\tforward-absolute-filepath\treverse-absolute-filepath" >> sample_${sample}.txt

for line in `cat sample.tmp`
do 
	echo -e "$line\t$PWD/fastq_multx_output/${line}.R1.fastq.gz\t$PWD/fastq_multx_output/${line}.R2.fastq.gz" >> sample_${sample}.txt

rm sample.tmp

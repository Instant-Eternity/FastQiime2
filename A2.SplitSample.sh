#########################################################################
# File Name: A2.SortData.sh
# Author: yonghengchana
# mail: hunterfirstone@i.smu.edu.cn
# Created Time: Wen  9/27 12:17:42 2023
#########################################################################
#!/bin/bash

mkdir fastq_multx_output-1/
mkdir fastq_multx_output-2/

time /bigdata/wangzhang_guest/chenpeng_project/00_software/fastq-multx/fastq-multx \
				 -B barcode.txt \
				 -m 1 \
				 -b 1.clean.fq.gz 2.clean.fq.gz \
				 -o %.R1.fastq \
				 -o %.R2.fastq

mv *.fastq fastq_multx_output-1/

time /bigdata/wangzhang_guest/chenpeng_project/00_software/fastq-multx/fastq-multx \
				 -B barcode.txt \
				 -m 1 \
				 -b 2.clean.fq.gz 1.clean.fq.gz \
				 -o %.R1.fastq \
				 -o %.R2.fastq

mv *.fastq fastq_multx_output-2/

mkdir fastq_multx_output/

for i in `ls fastq_multx_output-1/*.R1.fastq`; do a=${i/.R1.fastq/}; a=${a/fastq_multx_output-1\//}; echo "$a"; done > sample.list

for i in `cat sample.list`; do echo "cat fastq_multx_output-1/$i.R1.fastq fastq_multx_output-2/$i.R2.fastq > ./fastq_multx_output/$i.R1.fastq"; done > command.combine.R1.list

for i in `cat sample.list`; do echo "cat fastq_multx_output-1/$i.R2.fastq fastq_multx_output-2/$i.R1.fastq > ./fastq_multx_output/$i.R2.fastq"; done > command.combine.R2.list

time sh command.combine.R1.list
time sh command.combine.R2.list

rm -rf ./fastq_multx_output-*
for i in `ls fastq_multx_output/*.R2.fastq`; do python cut_reverseBarcode.py ${i} ${i}.fq; done
rm ./fastq_multx_output/*.R2.fastq
ls ./fastq_multx_output/*.fastq.fq |awk -F ".fq" '{print "mv "$0" "$1$2""}'|bash

gzip ./fastq_multx_output/*.fastq.fq
#sed -i '$d' sample.list

#########################################################################
# File Name: A2.SplitSample.sh
# Author: yonghengchana
# mail: hunterfirstone@i.smu.edu.cn
# Created Time: Wen  9/27 12:17:42 2023
#########################################################################
#!/bin/bash
# Function to display usage information
usage() {
    echo "Usage: $0 -b <barcode_file> -1 <input_R1_file> -2 <input_R2_file>"
    echo "       [-h] [-o <output_directory>]"
    echo ""
    echo "Split and merge FASTQ files using fastq-multx."
    echo ""
    echo "Options:"
    echo "  -b <barcode_file>   Path to the barcode file."
    echo "  -1 <input_R1_file>  Path to the input R1 FASTQ file."
    echo "  -2 <input_R2_file>  Path to the input R2 FASTQ file."
    echo "  -o <output_directory>  Output directory (default: fastq_multx_output/)."
    echo "  -v                  Version information."
    echo "  -h                  Display this help message."
    exit 1
}

display_version() {
    #echo -e "\e[1mSoftware\tVersion\e[0m"
    echo "$(tput bold)Software\tVersion$(tput sgr0)"
    echo "fastq-multx\t\t1.4.3"
}

split_marge(barcode.txt, 1.clean.fq.gz, 2.clean.fq.gz) {
    mkdir fastq_multx_output-1/
    mkdir fastq_multx_output-2/

    time fastq-multx -B barcode.txt \
        -m 1 \
        -b 1.clean.fq.gz 2.clean.fq.gz \
        -o %.R1.fastq \
        -o %.R2.fastq

    mv *.fastq fastq_multx_output-1/

    time fastq-multx -B barcode.txt \
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
}

# Set default values
output_directory="fastq_multx_output"

# Process command line options using getopts
while getopts ":b:1:2:o:hv" opt; do
    case $opt in
        b)
            barcode_file="$OPTARG"
            ;;
        1)
            input_R1_file="$OPTARG"
            ;;
        2)
            input_R2_file="$OPTARG"
            ;;
        o)
            output_directory="$OPTARG"
            ;;
        v)
            display_version
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check for the presence of required options
if [ -z "$barcode_file" ] || [ -z "$input_R1_file" ] || [ -z "$input_R2_file" ]; then
    echo "Error: Missing required options."
    usage
fi

# Create output directory if it doesn't exist
mkdir -p "$output_directory"

# Main
split_marge(barcode.txt, 1.clean.fq.gz, 2.clean.fq.gz)

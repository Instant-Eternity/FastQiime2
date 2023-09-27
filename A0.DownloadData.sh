#########################################################################
# File Name: A0.DownloadData.sh
# Author: yonghengchana
# mail: hunterfirstone@i.smu.edu.cn
# Created Time: Wen  9/27 12:17:42 2023
#########################################################################
#!/bin/bash
# Define a function to display usage information
usage() {
    echo "Usage: $0 [-h] [-d <output_directory>] <data_list_file>"
    echo "Download SRA data from a list of accession numbers."
    echo ""
    echo "Options:"
    echo "  -h              Display this help message."
    echo "  -v              Version information."
    echo "  -d <directory>  Specify the output directory (default: CleanData)."
    echo ""
    echo "Arguments:"
    echo "  <data_list_file>  File containing a list of SRA accession numbers."
    exit 1
}

display_version() {
    #echo -e "\e[1mSoftware\tVersion\e[0m"
    echo "$(tput bold)Software\tVersion$(tput sgr0)"
    echo "prefetch\t\t3.0.7"
    echo "fastq-dump\t\t3.0.7"
}

# Set default values
output_directory="CleanData"

# Process command line options using getopts
while getopts ":hvd:" opt; do
    case $opt in
        h)
            usage
            ;;
        v)
            display_version
            ;;
        d)
            output_directory="$OPTARG"
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

# Remove the processed options from the command line arguments
shift $((OPTIND-1))

# Check for the presence of the data list file argument
if [ $# -eq 0 ]; then
    echo "Error: Missing data list file argument."
    usage
fi

# Directory to save the download data
mkdir -p "$output_directory"

# List of SRA accession numbers
data_list_file="$1"

while read -r accession; do
    echo "Downloading ${accession}..."
    prefetch -O "$PWD/$output_directory" "$accession"
    fastq-dump --split-3 "$PWD/$output_directory/${accession}/${accession}.sra"
done < "$data_list_file"

echo "All downloads complete"

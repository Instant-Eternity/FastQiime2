#!/usr/bin/bash
sample=GP
mkdir result_${sample}
#-----Import Data-----
time qiime tools import \
	--type SampleData[PairedEndSequencesWithQuality] \
 	--input-path $PWD/sample_${sample}.txt \
  	--output-path $PWD/result_${sample}/R1.${sample}.demux.qza\
   --input-format PairedEndFastqManifestPhred33V2

#-----Cut primer sequence-----
time qiime cutadapt trim-paired \
	--i-demultiplexed-sequences $PWD/result_${sample}/R1.${sample}.demux.qza \
	--p-front-f CCTAYGGGRBGCASCAG \
	--p-front-r GGACTACNNGGGTATCTAAT\
	--o-trimmed-sequences $PWD/result_${sample}/R1.${sample}.paired-end-demux.qza \
	--verbose &> $PWD/result_${sample}/primer_trimming.log

#-----Visualization-----
time qiime demux summarize \
	--i-data $PWD/result_${sample}/R1.${sample}.paired-end-demux.qza \
	--o-visualization $PWD/result_${sample}/R1.${sample}.paired-end-demux.qzv

#-----Denoise-----
time qiime dada2 denoise-paired \
    --i-demultiplexed-seqs $PWD/result_${sample}/R1.${sample}.paired-end-demux.qza \
    --p-n-threads 12 \
    --p-trim-left-f 0 --p-trim-left-r 0 \
    --p-trunc-len-f 0 --p-trunc-len-r 0 \
	--o-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
 	--o-representative-sequences $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
  	--o-denoising-stats $PWD/result_${sample}/R2.${sample}.denoising-stats.qza

time qiime metadata tabulate \
	--m-input-file $PWD/result_${sample}/R2.${sample}.denoising-stats.qza \
	--o-visualization $PWD/result_${sample}/R2.${sample}.denoising-stats.qzv

time qiime feature-table summarize \
	--i-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
 	--o-visualization $PWD/result_${sample}/R2.${sample}.dada2-table.qzv \
  	--m-sample-metadata-file metadata_${sample}.txt

time qiime feature-table tabulate-seqs \
    --i-data $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
    --o-visualization $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qzv

#-----Constructing Evolutionary Tree-----
time qiime phylogeny align-to-tree-mafft-fasttree \
	--i-sequences $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
	--o-alignment $PWD/result_${sample}/R3.${sample}.aligned-rep-seqs.qza \
	--o-masked-alignment $PWD/result_${sample}/R3.${sample}.masked-aligned-rep-seqs.qza \
 	--o-tree $PWD/result_${sample}/R3.${sample}.unrooted-tree.qza \
  	--o-rooted-tree $PWD/result_${sample}/R3.${sample}.rooted-tree.qza

time qiime tools export \
	--input-path $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
	--output-path $PWD/result_${sample}/R2.${sample}.exported-feature-table

time biom convert -i $PWD/result_${sample}/R2.${sample}.exported-feature-table/feature-table.biom \
	-o $PWD/result_${sample}/R2.${sample}.exported-feature-table/feature-table.txt \
	--to-tsv

'''
for level in 2 3 4 5 6
do
	echo ${level}
	time qiime taxa collapse \
		--i-table $PWD/result_${sample}/R6.gg2.biom.qza \
		--i-taxonomy $PWD/result_${sample}/R7.gg2.taxonomy.qza \
		--p-level ${level} \
		--o-collapsed-table $PWD/result_${sample}/R7.${sample}.l${level}.phyla-table.qza 

	time qiime feature-table relative-frequency \
		--i-table $PWD/result_${sample}/R7.${sample}.l${level}.phyla-table.qza \
		--o-relative-frequency-table $PWD/result_${sample}/R7.${sample}.l${level}.prel-phyla-table.qza

	time qiime tools export \
		--input-path $PWD/result_${sample}/R7.${sample}.l${level}.prel-phyla-table.qza \
		--output-path $PWD/result_${sample}/R7.${sample}.l${level}.rel-table

	time biom convert \
		-i $PWD/result_${sample}/R7.${sample}.l${level}.rel-table/feature-table.biom \
		-o $PWD/result_${sample}/R7.${sample}.l${level}.rel-table/rel-phyla-table.tsv --to-tsv
done
'''

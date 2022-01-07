#!/usr/bin/bash
sample=GML_AC
mkdir result_${sample}
#-----Import Data-----
time qiime tools import \
        --type SampleData[PairedEndSequencesWithQuality] \
        --input-path /bigdata/wangzhang_guest/chenpeng_project/01_data/18_GML_16S/sample_${sample}.txt \
        --output-path $PWD/result_${sample}/R1.${sample}.demux.qza\
        --input-format PairedEndFastqManifestPhred33V2

#-----Cut primer sequence-----
time qiime cutadapt trim-paired \
        --i-demultiplexed-sequences $PWD/result_${sample}/R1.${sample}.demux.qza \
        --p-front-f GTGTGYCAGCMGCCGCGGTAA \
        --p-front-r CCGGACTACNVGGGTWTCTAAT  \
        --o-trimmed-sequences $PWD/result_${sample}/R1.${sample}.paired-end-demux.qza \
        --verbose \
        &> $PWD/result_${sample}/primer_trimming.log

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

#-----Quality Control------
time qiime quality-control exclude-seqs \
        --i-query-sequences $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
        --i-reference-sequences /bigdata/wangzhang_guest/chenpeng_project/04_pipeline/03_qiime2/ref-seqs.qza \
        --p-method vsearch \
        --p-perc-identity 0.97 \
        --p-perc-query-aligned 0.95 \
        --p-threads 4 \
        --o-sequence-hits $PWD/result_${sample}/R3.${sample}.hits.qza \
        --o-sequence-misses $PWD/result_${sample}/R3.${sample}.misses.qza \
        --verbose

#-----Characteristic table and representative sequence statistics-----
time qiime feature-table filter-features \
        --i-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
        --m-metadata-file $PWD/result_${sample}/R3.${sample}.misses.qza \
        --o-filtered-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --p-exclude-ids

time qiime feature-table summarize \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --o-visualization $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qzv \
        --m-sample-metadata-file metadata_${sample}.txt

time qiime feature-table tabulate-seqs \
        --i-data $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
        --o-visualization $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qzv

#-----Constructing Evolutionary Tree-----
time qiime phylogeny align-to-tree-mafft-fasttree \
        --i-sequences $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
        --o-alignment $PWD/result_${sample}/R5.${sample}.aligned-rep-seqs.qza \
        --o-masked-alignment $PWD/result_${sample}/R5.${sample}.masked-aligned-rep-seqs.qza \
        --o-tree $PWD/result_${sample}/R5.${sample}.unrooted-tree.qza \
        --o-rooted-tree $PWD/result_${sample}/R5.${sample}.rooted-tree.qza

min=2949
#-----Computing Core Diversity-----
time qiime diversity core-metrics-phylogenetic \
        --i-phylogeny $PWD/result_${sample}/R5.${sample}.rooted-tree.qza \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --p-sampling-depth ${min} \
        --m-metadata-file metadata_${sample}.txt \
        --output-dir $PWD/result_${sample}/R6.${sample}.core-metrics-results

#-----Significance Analysis And Visualization Between Alpha Diversity Groups-----

for index in {faith_pd,shannon,observed_features,evenness}
do
    time qiime diversity alpha-group-significance \
        --i-alpha-diversity $PWD/result_${sample}/R6.${sample}.core-metrics-results/${index}_vector.qza \
        --m-metadata-file metadata_${sample}.txt \
        --o-visualization $PWD/result_${sample}/R6.${sample}.core-metrics-results/${index}-group-significance.qzv
done

max=41668

#-----Alpha Diversity Sparse Curve-----
time qiime diversity alpha-rarefaction \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --i-phylogeny $PWD/result_${sample}/R5.${sample}.rooted-tree.qza \
        --p-max-depth ${max} \
        --m-metadata-file metadata_${sample}.txt \
        --o-visualization $PWD/result_${sample}/R7.${sample}.alpha-rarefaction.qzv

#distance=weighted_unifrac #unweighted_unifrac,bray_curtis,weighted_unifrac,jaccard
column=Group
#-----Significance Analysis And Visualization Of Beta Diversity Between Groups-----
for distance in {unweighted_unifrac,bray_curtis,weighted_unifrac,jaccard}
do
    time qiime diversity beta-group-significance \
        --i-distance-matrix $PWD/result_${sample}/R6.${sample}.core-metrics-results/${distance}_distance_matrix.qza \
        --m-metadata-file metadata_${sample}.txt \
        --m-metadata-column ${column} \
        --o-visualization $PWD/result_${sample}/R6.${sample}.core-metrics-results/${distance}-${column}-significance.qzv \
        --p-pairwise
done

#-----Species Composition Analysis-----
time qiime feature-classifier classify-sklearn \
        --i-classifier /bigdata/wangzhang_guest/chenpeng_project/04_pipeline/03_qiime2/gg-13-8-99-nb-classifier.qza \
        --i-reads $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
        --o-classification $PWD/result_${sample}/R8.${sample}.taxonomy.qza

time qiime metadata tabulate \
        --m-input-file $PWD/result_${sample}/R8.${sample}.taxonomy.qza \
        --o-visualization $PWD/result_${sample}/R8.${sample}.taxonomy.qzv

time qiime taxa barplot \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --i-taxonomy $PWD/result_${sample}/R8.${sample}.taxonomy.qza \
        --m-metadata-file metadata_${sample}.txt \
        --o-visualization $PWD/result_${sample}/R9.${sample}.taxa-bar-plots.qzv

#-----Calculate difference characteristics-----
time qiime composition add-pseudocount \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --o-composition-table $PWD/result_${sample}/R10.${sample}.comp-table-l6.qza

column=Group

time qiime composition ancom \
        --i-table $PWD/result_${sample}/R10.${sample}.comp-table-l6.qza \
        --m-metadata-file metadata_${sample}.txt \
        --m-metadata-column ${column} \
        --o-visualization $PWD/result_${sample}/R10.${sample}.ancom-${column}.qzv

time qiime taxa collapse \
        --i-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
        --i-taxonomy $PWD/result_${sample}/R8.${sample}.taxonomy.qza \
        --p-level 6 \
        --o-collapsed-table $PWD/result_${sample}/R11.${sample}.taxonomy.table-l6.qza

time qiime composition add-pseudocount \
        --i-table $PWD/result_${sample}/R11.${sample}.taxonomy.table-l6.qza \
        --o-composition-table $PWD/result_${sample}/R12.${sample}.comp-table-l6.qza

time qiime composition ancom \
        --i-table $PWD/result_${sample}/R12.${sample}.comp-table-l6.qza \
        --m-metadata-file metadata_${sample}.txt \
        --m-metadata-column ${column} \
        --o-visualization $PWD/result_${sample}/R13.${sample}.l6-ancom-${column}.qzv

#!/usr/bin/bash
sample=GP
min=45499

#-----Computing Core Diversity-----
time qiime diversity core-metrics-phylogenetic \
	--i-phylogeny $PWD/result_${sample}/R3.${sample}.rooted-tree.qza \
 	--i-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
  	--p-sampling-depth ${min} \
   	--m-metadata-file metadata_${sample}.txt \
	--output-dir $PWD/result_${sample}/R4.${sample}.core-metrics-results

#-----Significance Analysis And Visualization Between Alpha Diversity Groups-----

for index in {faith_pd,shannon,observed_features,evenness}
do 
	time qiime diversity alpha-group-significance \
		--i-alpha-diversity $PWD/result_${sample}/R4.${sample}.core-metrics-results/${index}_vector.qza \
		--m-metadata-file metadata_${sample}.txt \
		--o-visualization $PWD/result_${sample}/R4.${sample}.core-metrics-results/${index}-group-significance.qzv
done

max=60854

#-----Alpha Diversity Sparse Curve-----
time qiime diversity alpha-rarefaction \
	--i-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
	--i-phylogeny $PWD/result_${sample}/R3.${sample}.rooted-tree.qza \
	--p-max-depth ${max} \
	--m-metadata-file metadata_${sample}.txt \
	--o-visualization $PWD/result_${sample}/R5.${sample}.alpha-rarefaction.qzv

#distance=weighted_unifrac #unweighted_unifrac,bray_curtis,weighted_unifrac,jaccard
column=Group

#-----Significance Analysis And Visualization Of Beta Diversity Between Groups-----

for distance in {unweighted_unifrac,bray_curtis,weighted_unifrac,jaccard}
do
	time qiime diversity beta-group-significance \
        --i-distance-matrix $PWD/result_${sample}/R4.${sample}.core-metrics-results/${distance}_distance_matrix.qza \
        --m-metadata-file metadata_${sample}.txt \
        --m-metadata-column ${column} \
        --o-visualization $PWD/result_${sample}/R4.${sample}.core-metrics-results/${distance}-${column}-significance.qzv \
        --p-pairwise
done

#-----Species Composition Analysis-----

qiime tools import \
    --type 'FeatureData[Sequence]' \
    --input-path 99_otus.fasta \
    --output-path 99_otus.qza

time qiime greengenes2 filter-features \
	--i-feature-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
	--i-reference 2022.10.taxonomy.md5.nwk.qza \
	--o-filtered-feature-table R6.table_gg2.biom.qza

#time qiime greengenes2 taxonomy-from-table \
#	--i-reference-taxonomy 2022.10.taxonomy.md5.nwk.qza \
#	--i-table R6.table_gg2.biom.qza \
#	--o-classification R7.gg2.taxonomy.qza

#time qiime greengenes2 relabel \
#	--i-feature-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
#	--i-reference-label-map gg2-2022.8-label_map.qza \
#	--p-as-md5 \
#	--o-relabeled-table $PWD/result_${sample}/R8.${sample}.gg2-table.qza

time qiime greengenes2 non-v4-16s \
	--i-table $PWD/result_${sample}/R2.${sample}.dada2-table.qza \
	--i-sequences $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
	--i-backbone 2022.10.backbone.full-length.fna.qza \
	--o-mapped-table $PWD/result_${sample}/R6.gg2.biom.qza \
	--o-representatives $PWD/result_${sample}/R6.gg2.fna.qza

time qiime greengenes2 taxonomy-from-table \
	--i-reference-taxonomy 2022.10.backbone.full-length.fna.qza \
	--i-table $PWD/result_${sample}/R6.gg2.biom.qza \
	--o-classification $PWD/result_${sample}/R7.gg2.taxonomy.qza

#time qiime greengenes2 taxonomy-from-features \
#	--i-reference-taxonomy 2022.10.taxonomy.asv.nwk.qza \
#	--i-reads $PWD/result_${sample}/icu.gg2.fna.qza \
#	--o-classification $PWD/result_${sample}/icu.gg2.taxonomy.qza

qiime greengenes2 filter-features \
	--i-feature-table $PWD/result_${sample}/R4.${sample}.no-miss-table-dada2.qza \
	--i-reference 2022.10.taxonomy.md5.nwk.qza \
	--o-filtered-feature-table $PWD/result_${sample}/R2.${sample}.gg2-rep-seqs.qza

qiime greengenes2 taxonomy-from-table \
	--i-reference-taxonomy 2022.10.taxonomy.md5.nwk.qza \
	--i-table $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
	--o-classification $PWD/result_${sample}/R8.${sample}.taxonomy.qza

time qiime feature-classifier classify-sklearn \
        --i-classifier gg-13-8-99-nb-classifier.qza \
        --i-reads $PWD/result_${sample}/R2.${sample}.dada2-rep-seqs.qza \
        --o-classification $PWD/result_${sample}/R8.${sample}.taxonomy.qza

wget http://ftp.microbio.me/greengenes_release/2022.10/2022.10.taxonomy.asv.nwk.qza

wget http://ftp.microbio.me/greengenes_release/current/2022.10.taxonomy.md5.nwk.qza

$ qiime greengenes2 filter-features \
>     --i-feature-table icu.biom.qza \
>     --i-reference 2022.10.taxonomy.asv.nwk.qza \
>     --o-filtered-feature-table icu_gg2.biom.qza
Saved FeatureTable[Frequency] to: icu_gg2.biom.qza

$ qiime greengenes2 taxonomy-from-table \
>     --i-reference-taxonomy 2022.10.taxonomy.asv.nwk.qza \
>     --i-table icu_gg2.biom.qza \
>     --o-classification icu_gg2.taxonomy.qza

time qiime metadata tabulate \
        --m-input-file $PWD/result_${sample}/R7.gg2.taxonomy.qza \
        --o-visualization $PWD/result_${sample}/R7.gg2.taxonomy.qzv

time qiime taxa barplot \
        --i-table $PWD/result_${sample}/R6.gg2.biom.qza \
        --i-taxonomy $PWD/result_${sample}/R7.gg2.taxonomy.qza \
        --m-metadata-file metadata_${sample}.txt \
        --o-visualization $PWD/result_${sample}/R8.${sample}.taxa-bar-plots.qzv

#-----Calculate difference characteristics-----
time qiime composition add-pseudocount \
        --i-table $PWD/result_${sample}/R6.gg2.biom.qza \
        --o-composition-table $PWD/result_${sample}/R9.${sample}.comp-table-l6.qza

column=Group

time qiime composition ancom \
        --i-table $PWD/result_${sample}/R9.${sample}.comp-table-l6.qza \
        --m-metadata-file metadata_${sample}.txt \
        --m-metadata-column ${column} \
        --o-visualization $PWD/result_${sample}/R9.${sample}.ancom-${column}.qzv

time qiime taxa collapse \
        --i-table $PWD/result_${sample}/R6.gg2.biom.qza \
        --i-taxonomy $PWD/result_${sample}/R7.gg2.taxonomy.qza \
        --p-level 6 \
        --o-collapsed-table $PWD/result_${sample}/R10.${sample}.taxonomy.table-l6.qza

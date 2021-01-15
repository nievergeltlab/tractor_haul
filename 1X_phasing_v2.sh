#!/bin/bash

#chromosome is set based on array number
 chr=$SLURM_ARRAY_TASK_ID

#Number of threads is based on N CPUs on node - 1
 nodeuse=$(($SLURM_CPUS_ON_NODE - 1))


$eagle \
    --vcfRef /home/maihofer/hrc_phase/HRC.r1-1.EGA.GRCh37.chr"$chr".impute.bcf.bgz \
    --geneticMapFile=/home/maihofer/hrc_phase/genetic_map_chr"$chr"_combined_b37.chr.txt \
    --vcfTarget temp/"$study"_chr"$chr".vcf.gz \
    --outPrefix="$study"/phased/"$study"_phased_chr"$chr" \
    --allowRefAltSwap \
    --numThreads=$nodeuse
    
#/home/maihofer/hrc_phase/HRC.r1-1.EGA.GRCh37.chr"$chr".impute.bcf.bgz
#/home/maihofer/hrc_phase/genetic_map_chr"$chr"_combined_b37.chr.txt


#Note:
# This requirement can be relaxed via the --allowRefAltSwap flag,
 # which causes REF/ALT swaps to be tolerated (and automatically flipped)
 # for true SNPs. For indels, REF/ALT swaps are always dropped due to the 
 # possibility of different indels appearing to be the same. 
 # (Thanks to Giulio Genovese for pointing out this subtlety.) 


#!/bin/bash
# phases each data file by chromosome
# chromosome is set based on array number
chr=$SLURM_ARRAY_TASK_ID

# Number of threads is based on N CPUs on node - 1
nodeuse=$(($SLURM_CPUS_ON_NODE - 1))

eagle \
  --vcfRef /home/maihofer/hrc_phase/HRC.r1-1.EGA.GRCh37.chr${chr}.impute.bcf.bgz \
  --geneticMapFile=/home/maihofer/hrc_phase/genetic_map_chr${chr}_combined_b37.chr.txt \
  --vcfTarget $WORKING_DIR/$study/unphased/${study}_unphased_chr${chr}.vcf.gz \
  --outPrefix=$WORKING_DIR/$study/phased/${study}_phased_chr${chr} \
  --allowRefAltSwap \
  --numThreads=$nodeuse

# export $(cat .env | xargs); sbatch --array=1-22 --time=12:00:00 --error $WORKING_DIR/errandout/${study}/phasing/phase_%a.e --output $WORKING_DIR/errandout/${study}/phasing/phase_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  00b_phasing.sh -D $WORKING_DIR

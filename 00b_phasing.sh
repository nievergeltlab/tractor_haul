#!/bin/bash
# phases each data file by chromosome
# chromosome is set based on array number
chr=$SLURM_ARRAY_TASK_ID
# Number of threads is based on N CPUs on node - 1
nodeuse=$(($SLURM_CPUS_ON_NODE - 1))

eagle \
  --geneticMapFile=/home/maihofer/hrc_phase/genetic_map_chr${chr}_combined_b37.chr.txt \
  --bfile=$input_data_file \
  --outPrefix=${TMPDIR}/${study}_phased_chr${chr} \
  --allowRefAltSwap \
  --numThreads=$nodeuse \
  --chrom=$chr \
  --exclude=${WORKING_DIR}/${study}/ambiguous_snps.txt

# change columns from [FID, IID, #missing] to [FID_IID, FID_IID, #missing] (Shapeit v2 hap/sample format is weird)
awk 'NR<=2{print}NR>2{print $1"_"$2,$1"_"$2,$3}' ${TMPDIR}/${study}_phased_chr${chr}.sample > ${TMPDIR}/${study}_phased_chr${chr}.sample.fixed

shapeit -convert --input-haps ${TMPDIR}/${study}_phased_chr${chr}.haps.gz ${TMPDIR}/${study}_phased_chr${chr}.sample.fixed \
  --output-vcf ${WORKING_DIR}/${study}/phased/${study}_phased_chr${chr}.vcf.gz

# export $(cat .env | xargs); sbatch --array=1-22 --time=12:00:00 --error $WORKING_DIR/errandout/${study}/phasing/phase_%a.e --output $WORKING_DIR/errandout/${study}/phasing/phase_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  00c_phasing.sh -D $WORKING_DIR

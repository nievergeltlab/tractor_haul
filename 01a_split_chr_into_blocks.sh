#!/bin/bash
# splits chromosomes into 50MB (megabases) blocks with 5MB buffers to preserve memory (and runtime) for xgmix
DATADIR=${WORKING_DIR}/${study}/phased
chr=$SLURM_ARRAY_TASK_ID
# lengths of chromosomes in MB
CHR_LENS=(249 242 198 190 182 170 159 145 138 134 135 133 114 107 102 90 83 80 59 64 47 51)

len=$(( ${CHR_LENS[chr-1]} + 1 ))
for ((i = 0; i < len; i += 50)); do
  begin=$(( $i - 5 ))
  end=$(( $i + 55 ))
  echo '' | awk -v begin=$begin -v end=$end '{print begin * 1e6 " " end * 1e6}'
  zcat ${DATADIR}/${study}_phased_chr${chr}.vcf.gz | awk -v begin=$begin -v end=$end '{if(/^#/ || ($2 >= begin * 1e6 && $2 <= end * 1e6)){print }}' | gzip -c > ${DATADIR}/${study}_phased_chr${chr}_${i}.vcf.gz
  zcat ${REF_DIR}/refpanel_chr${chr}.vcf.gz | awk -v begin=$begin -v end=$end '{if(/^#/ || $1 == "#CHROM" || ($2 >= begin * 1e6 && $2 <= end * 1e6)){print }}' | gzip -c > ${REF_DIR}/refpanel_chr${chr}_${i}.vcf.gz
done

# export $(cat .env | xargs); sbatch --array=1-22 --time=01:00:00 --error ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks_%a.e --output ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks%a.o  --export=ALL,WORKING_DIR=$WORKING_DIR,REF_DIR=$REF_DIR,study=$study  01a_split_chr_into_blocks.sh -D $WORKING_DIR

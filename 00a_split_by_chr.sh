#!/bin/bash
#splits single data file by chromosome
chr=$SLURM_ARRAY_TASK_ID
plink --bfile $input_data_file --chr $chr --make-bed --out $WORKING_DIR/$study/unphased/${study}_unphased_chr${chr}
plink --bfile ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr} --recode vcf --out $WORKING_DIR/$study/unphased/${study}_unphased_chr${chr}
bgzip -f ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr}.vcf
tabix -f -p vcf ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr}.vcf.gz
rm ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr}.bed
rm ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr}.fam
rm ${WORKING_DIR}/${study}/unphased/${study}_unphased_chr${chr}.bim

# export $(cat .env | xargs); sbatch --array=1-22 --time=00:35:00 --error ${WORKING_DIR}/errandout/${study}/splitting/split_%a.e --output ${WORKING_DIR}/errandout/${study}/splitting/split_%a.o  --export=ALL,WORKING_DIR=$WORKING_DIR,study=$study  00a_split_by_chr.sh -D $WORKING_DIR

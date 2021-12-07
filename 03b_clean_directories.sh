#!/bin/bash
# clean directories of split files to preserve disk space
# get WORKING_DIR and study variables
export $(cat .env | xargs)
# chromosome lengths in mega-basepairs
CHR_LENS=(249 242 198 190 182 170 159 145 138 134 135 133 114 107 102 90 83 80 59 64 47 51)
for chr in {1..22}; do
  len=$(( ${CHR_LENS[chr-1]} + 1 ))
  for ((i = 0; i <= len; i += 50)); do
    rm ${WORKING_DIR}/${study}/phased/${study}_phased_chr${chr}_${i}.vcf.gz
    rm ${REF_DIR}/refpanel_chr${chr}_${i}.vcf.gz
    rm -r ${WORKING_DIR}/predictions/${study}/${chr}_${i}
  done
done

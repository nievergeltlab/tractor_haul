#!/bin/bash
# get env variables
export $(cat .env | xargs)
bimfile=${input_data_file}.bim
grep -P "A\tT" $bimfile  > ${WORKING_DIR}/${study}/ambiguous_snps.txt
grep -P "T\tA" $bimfile  >> ${WORKING_DIR}/${study}/ambiguous_snps.txt
grep -P "C\tG" $bimfile  >> ${WORKING_DIR}/${study}/ambiguous_snps.txt
grep -P "G\tC" $bimfile  >> ${WORKING_DIR}/${study}/ambiguous_snps.txt

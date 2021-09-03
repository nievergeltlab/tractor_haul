#!/bin/bash
# get env variables
export $(cat .env | xargs)
LANC_DIR=${WORKING_DIR}/lanc_expansion
mkdir -p ${WORKING_DIR}/plink_input/${study}/${chr}

# create pvar file from tsv file
datafile=${WORKING_DIR}/${study}/phased/${study}_phased_chr${chr}.vcf.gz
pvarfile=${WORKING_DIR}/plink_input/${study}/${chr}/${study}_${chr}.pvar
zcat $datafile | cut -f1-10 > $pvarfile

plink2 --import-dosage ${LANC_DIR}/lanctotals/${study}/${chr}/${study}_${chr}.total.anc2.msp.tsv.gz format=1 noheader \
 --fam $fam_file --glm local-covar=${LANC_DIR}/lanctotals/${study}/${chr}/${study}_${chr}.total.covar.msp.tsv.gz \
 local-psam=$fam_file local-pvar=$pvarfile --out ${LANC_DIR}/plink_output/${study}/${chr}/${study}_${chr}_lanc

# export $(cat .env | xargs); sbatch --array=22 --time=12:00:00 --error ${WORKING_DIR}/errandout/${study}/regression/regression_%a.e --output ${WORKING_DIR}/errandout/${study}/regression/regression_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  06_run_plink_glm.sh -D $WORKING_DIR

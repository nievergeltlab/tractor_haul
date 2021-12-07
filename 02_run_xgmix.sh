#!/bin/bash
#Must use helper to submit jobs - this passes the ${chr} and ${begin} environmental variables

#Make output directory where predictions will be saved
mkdir -p ${WORKING_DIR}/predictions/${study}/${chr}_${begin}

#Call into LISA temp dir
cd $TMPDIR

#Copy xgmix data over to temp dir. XGmix doesn't do paths well so its easier to copy the program to the temp dir and deal with that
rsync -rav ${WORKING_DIR}/XGMix-master/* ${TMPDIR} --exclude xgmix --exclude generated_data

#Make directories for XGmix outputs..
mkdir -p xgmix
mkdir -p generated_data
mkdir -p models
mkdir -p xgmix/${study}_${chr}_${begin}

##Create reference panel

#Copy reference data to the TEMP DIR, this should speed things up

#Copy a phased dataset for testing:
cp ${WORKING_DIR}/${study}/phased/${study}_phased_chr${chr}_${begin}.vcf.gz .

#Make sure reference population origin file is tab delimited
#Make sure recomb file is tab delimited

#Run xgmix
#python3 XGMIX.py <query_file>                      <genetic_map_file>                                                    <output_basename>      <chr_nr> <phase> <path_to_model>
python3 XGMIX.py ${study}_phased_chr${chr}_${begin}.vcf.gz  ${WORKING_DIR}/recombination_maps/HapMapcomb_genmap_chr${chr}_tab.txt  xgmix/${study}_${chr}_${begin} ${chr}    TRUE  ${WORKING_DIR}/models/${study}/${chr}_${begin}/models/model_chm_${chr}/model_chm_${chr}.pkl

#OUTPUTS:

#Rename phased file so it doesn't have the same name as the other phased files..
mv xgmix/${study}_${chr}_${begin}/query_file_phased.vcf xgmix/${study}_${chr}_${begin}/${study}_${chr}_${begin}.vcf

#bgzip phased file
bgzip xgmix/${study}_${chr}_${begin}/${study}_${chr}_${begin}.vcf

#Copy ancestry calls
rsync -rav xgmix/${study}_${chr}_${begin}/* ${WORKING_DIR}/predictions/${study}/${chr}_${begin} --exclude generated_data

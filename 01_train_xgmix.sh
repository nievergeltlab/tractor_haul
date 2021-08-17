#!/bin/bash
#Must use helper to submit jobs - this passes the ${chr} and ${begin} environmental variables

##Ancestry panel code:

#Call into LISA temp dir
cd $TMPDIR

#Copy xgmix data over to temp dir. XGmix doesn't do paths well so its easier to copy the program to the temp dir and deal with that
rsync -rav ${WORKING_DIR}/XGMix-master/* $TMPDIR --exclude xgmix --exclude generated_data


#Call into temp dir
cd $TMPDIR

#Make directories for XGmix outputs..
mkdir -p xgmix
mkdir -p generated_data
mkdir -p models
mkdir -p ${WORKING_DIR}/models/${study}/${chr}_${begin}

##Create reference panel

#Copy reference and test data to the working directory, this will enhance speed generally

#Copy reference population file
cp ${WORKING_DIR}/1kg_hgdp/1kg_hgdp_refpanel_chr${chr}_${begin}.vcf.gz .

#Copy a phased dataset for testing:
cp ${WORKING_DIR}/${study}/phased/${study}_phased_chr${chr}_${begin}.vcf.gz .

#Make sure reference population origin file is tab delimited
#Make sure recomb file is tab delimited

#Run xgmix
#python3 XGMIX.py <query_file>                       <genetic_map_file>                                                    <output_basename>       <chr_nr> <phase> <reference_file>               <sample_map_file>
python3 XGMIX.py ${study}_phased_chr${chr}_${begin}.vcf.gz  ${WORKING_DIR}/recombination_maps/HapMapcomb_genmap_chr${chr}_tab.txt  xgmix/${study}_${chr}_${begin} ${chr} FALSE 1kg_hgdp_refpanel_chr${chr}_${begin}.vcf.gz  $ref_subjects

#OUTPUTS:

#Copy ancestry calls and models
rsync -rav xgmix/${study}_${chr}_${begin}/* ${WORKING_DIR}/models/${study}/${chr}_${begin} --exclude generated_data

#simulation data currently excluded

#!/bin/bash

##Preliminary information:

#This runs XGmix using a premade panel. You should have run the training step before hand to generate a reference panel to be used here

#If you haven't done this upon starting LISA, load requisite libraries and modules before you run this job.
 # LD_LIBRARY_PATH=/home/czai/libraries/lib:$LD_LIBRARY_PATH
 # module load 2019
 # module load OpenMPI/3.1.4-GCC-8.3.0
 # module load Python/3.6.6-intel-2019b
 
##Ancestry panel code:

#Set chromosome based on array info 
chr=$SLURM_ARRAY_TASK_ID

#Call into LISA temp dir
 cd $TMPDIR
 
#Copy xgmix data over to temp dir. XGmix doesn't do paths well so its easier to copy the program to the temp dir and deal with that
 rsync -rav "$WORKING_DIR"/XGMix-master/* "$TMPDIR"/. --exclude xgmix --exclude generated_data


#Call into temp dir
 cd $TMPDIR

#Make directories for XGmix outputs..
#mkdir xgmix
 #mkdir generated_data
 #mkdir models

##Create reference panel 

#Copy reference data to the TEMP DIR, this should speed things up

#Copy a phased dataset for testing:
 cp "$WORKING_DIR"/"$study"/phased/"$study"_phased_chr"$chr".vcf.gz . 

#Make sure reference population origin file is tab delimited
#Make sure recomb file is tab delimited

#Run xgmix
#python3 XGMIX.py <query_file>                      <genetic_map_file>                                                    <output_basename>      <chr_nr> <phase> <path_to_model> 
 python3 XGMIX.py "$study"_phased_chr"$chr".vcf.gz  "$WORKING_DIR"/recombination_maps/HapMapcomb_genmap_chr"$chr"_tab.txt  xgmix/"$study"_"$chr" "$chr"    TRUE  "$WORKING_DIR"/refpanels/"$refpanel"/model_chm_"$chr".pkl

#OUTPUTS:

#Rename phased file so it doesn't have the same name as the other phased files..
 mv xgmix/"$study"_"$chr"/query_file_phased.vcf xgmix/"$study"_"$chr"/"$study"_"$chr".vcf

#bgzip phased file
 bgzip xgmix/"$study"_"$chr"/"$study"_"$chr".vcf

#Copy ancestry calls 

 rsync -rav xgmix/"$study"_"$chr"/* "$WORKING_DIR"/"$study"/"$study"_"$refpanel" --exclude generated_data


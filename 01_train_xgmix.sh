#!/bin/bash

##Preliminary information:

#This is to train the XGmix model on the reference panel
#This should only need to be run one time per panel and configuration settings (see config.py under XGmix-master for configuration options)

#Before you begin, this is REALLY(!) important:
#The annotation for the reference data should be the same as for the test data
#Namely, VCF files sometimes have 'chr' prefixing chromosome names. The usage of this prefix MUST be consistent across the training and test datasets, otherwise SNPs will not be found in the test data!!
#I recommend removing the chr prefix from the reference data before beginning, as I don't think phased eagle outputs have chr prefixes!

#ALSO YOU MUST BE ON THE SAME GENOME BUILD FOR TRAINING AND REFERENCE!!!!!!

#This command is meant to be submitted as a job. Do not submit these commands to the console in the normal way!

#i.e. the job should be submitted like this
#WORKING_DIR=/home/czai/ancestry
#sbatch --array=21 --time=1:05:00 --error errandout/train_xgmix.e_%a --output errandout/train_xgmix.o_%a  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  01_train_xgmix.sh -D $WORKING_DIR

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

#Copy reference and test data to the working directory, this will enhance speed generally

#Copy reference population file
 cp "$WORKING_DIR"/1kg_hgdp/1kg_hgdp_refpanel_chr"$chr".vcf.gz . 

#Copy a phased dataset for testing:
 cp "$WORKING_DIR"/"$study"/phased/"$study"_phased_chr"$chr".vcf.gz . 

#Make sure reference population origin file is tab delimited
#Make sure recomb file is tab delimited

#Run xgmix
#python3 XGMIX.py <query_file>                       <genetic_map_file>                                                    <output_basename>       <chr_nr> <phase> <reference_file>               <sample_map_file>
 python3 XGMIX.py "$study"_phased_chr"$chr".vcf.gz  "$WORKING_DIR"/recombination_maps/HapMapcomb_genmap_chr"$chr"_tab.txt  xgmix/"$study"_"$chr" "$chr" FALSE 1kg_hgdp_refpanel_chr"$chr".vcf.gz  "$WORKING_DIR"/1kg_hgdp/pgcptsdrefpops.txt

#OUTPUTS:

#Copy ancestry calls and models
 rsync -rav xgmix/"$study"_"$chr"/* "$WORKING_DIR"/XGMix-master/xgmix/. --exclude generated_data

#simulation data currently excluded

##Post panel construction steps

#Once all 22 chromosomes have completed, copy the model files into a reference panel directory , i.e.
#cp "$WORKING_DIR"/XGMix-master/xgmix/models/model_chm_*/model_chm*.pkl "$WORKING_DIR"/refpanel/PANELNAMEHERE/.



##
##Preliminary steps 
##
#You must run these commands every time you start a new session on LISA when you want to run XGMix. Only run once! You can adjust the .bashrc file to run this automatically.

#Run this command so it knows to look for libarchive here. 

 LD_LIBRARY_PATH=/home/czai/libraries/lib:$LD_LIBRARY_PATH
 
#Add BCFtools to path if it hasn't already been added
 export PATH=/home/czai/libraries/bcftools/bin:$PATH 
 
#Load python and MPI modules.
 module load 2019
 module load OpenMPI/3.1.4-GCC-8.3.0
 module load Python/3.6.6-intel-2019b
 module load R
 
#Set path to plink1.9 executable and eagle executable
 plink=/home/czai/ancestry/plink
 eagle=/home/czai/ancestry/Eagle_v2.4.1/eagle
 


##
##Analysis steps. Assumes that you have a reference panel made!
##
 
##Variables to be set by user:
 #Set study name (should match our abbreviation codes, calls specifically to these directories)
  study=mrsc

 #Set working directory. Should contain XGMix folder
  WORKING_DIR=/home/czai/ancestry
  
 #Specify ref panel folder name (within folder refpanels)
  refpanel=xgmdefault

##After setting variables above, run these commands:

#Call into working directory
 cd $WORKING_DIR

#Make a folder for the study outputs
 mkdir -p "$WORKING_DIR"/"$study"
 mkdir -p "$WORKING_DIR"/"$study"/"phased"
 mkdir -p "$WORKING_DIR"/"$study"/"$study"_"$refpanel"
 mkdir -p "$WORKING_DIR"/"$study"/"$study"_"$refpanel"/plots
 
#Makes a shortcut to where the PLINK format data is stored (otherwise, if you aren't storing your data somewhere else)
 ln -s /home/pgcdac/DWFV2CJb8Piv_0116_pgc_data/pts/wave3/v1/"$study"/cobg_dir_genome_wide/pts_"$study"_mix_am-qc.hg19.ch.fl.bg.bed "$study"/"$study"_bg_cogb.bed 
 ln -s /home/pgcdac/DWFV2CJb8Piv_0116_pgc_data/pts/wave3/v1/"$study"/cobg_dir_genome_wide/pts_"$study"_mix_am-qc.hg19.ch.fl.bg.bim "$study"/"$study"_bg_cogb.bim 
 ln -s /home/pgcdac/DWFV2CJb8Piv_0116_pgc_data/pts/wave3/v1/"$study"/cobg_dir_genome_wide/pts_"$study"_mix_am-qc.hg19.ch.fl.bg.fam "$study"/"$study"_bg_cogb.fam

#Identify the ambiguous alleles. These will be excluded!
 grep -P "A\tT" "$study"/"$study"_bg_cogb.bim  > "$study"/ambiguous_snps.txt
 grep -P "T\tA" "$study"/"$study"_bg_cogb.bim  >> "$study"/ambiguous_snps.txt
 grep -P "C\tG" "$study"/"$study"_bg_cogb.bim  >> "$study"/ambiguous_snps.txt
 grep -P "G\tC" "$study"/"$study"_bg_cogb.bim  >> "$study"/ambiguous_snps.txt

#Split up data by chromosome (outputs in folder "temp")
 sbatch --time=01:00:00 --error errandout/split_"$study".e_%a --output errandout/split_"$study".o_%a --export=ALL,study="$study",plinkpath=$plink,bfile="$study"/"$study"_bg_cogb,ambiguous="$study"/ambiguous_snps.txt  0X_split_chr_v2.sh -D $WORKING_DIR 

#Phase data. DO NOT RUN until previous job completes!
 sbatch --array=1-22 --time=03:05:00 --error errandout/phase_"$study".e_%a --output errandout/phase_"$study".o_%a  --export=ALL,study="$study",eagle="$eagle"  1X_phasing_v2.sh -D $WORKING_DIR 

#Run XGmix. DO NOT RUN until previous job completes!
 sbatch --array=15-22 --time=02:00:00 --error errandout/xgmix_"$study"_"$refpanel".e_%j_%a --output errandout/xgmix_"$study"_"$refpanel".o_%j_%a   --export=ALL,study="$study",refpanel=$refpanel,WORKING_DIR="$WORKING_DIR" 2X_xgmix_run.sh  -D $WORKING_DIR 

#Plot local ancestry of subjects. DO NOT RUN until previous job completes!
 sbatch  --time=01:00:00 --error errandout/lancplot_"$study"_"$refpanel".e_%j_%a --output errandout/lancplot_"$study"_"$refpanel".o_%j_%a   --export=ALL,study="$study",refpanel=$refpanel,WORKING_DIR="$WORKING_DIR" 3X_lanc_helper.sh  -D $WORKING_DIR 



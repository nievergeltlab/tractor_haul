# Tractor HAUL
Implementation of Tractor local ancestry pipeline not relying on HAIL  
last rev Jan 15, 2021

## Overview  
### 0) Install XGmix. 
   Follow steps in 00_xgmix_install.sh  
     
### 1) Create a panel for local ancestry inference using XGmix and a PHASED vcf of reference subjects with KNOWN population origins.  
Follow instructions in 01_train_xgmix.sh. 

This will generate a local ancestry panel, these will have to be copied into the reference panel folder (see code). Additional program settings that control the simulation and model calibration can be found in XGMix-master/config.py. It may be important to pay attention to these!  
     
   It is VERY important to note the following  :  
     A) the reference and test datasets MUST be on the same genome build  
     B) usage (or nonusage) of 'chr' prefix in VCF files must be consistent across datasets  
     
### 2) Call local ancestry in target populations  
   Follow instructions in 02_call_local_ancestry.sh  
   By default it is NOT set to correct phase (i.e. unkinking). 

     
     
### Other Usage Notes:  

The pipeline is a bit primitive, and is for most will be a hackable example rather than a push button interface  

  A) jobs are not automatically resubmitted if failed.  
  B) There is no job dependency programmed in, you have to manually check if a job finished before proceeding to the next step  
  C) You will have to go into the job scripts to set certain paths
  
#### SLURM: 
 This assumes that you have access to a SLURM computing system (eg LISA) 

##### If you do not have SLURM:  
   Run the contents of the job script commands in the shell. Because chromosomes are by default indexed by the array index number, you will have to create a for loop to replace the array indexing variable. ie. 
     
     for (SLURM_ARRAY_TASK_ID in seq 1 1 22) ; do ... job script contents ... ; done  ;  
     
   You'll also need to install whatever compiling libraries are necessary to install xgmix by yourself

#### If you do not have HRC reference panel
   Specify your own reference panel in the phasing script. 1000G phase 3 is a good bet.
     
#### XGmix Phase correction:  
   Correcting phase dramatically increases computation time. Time scales up dramatically with the number of reference populations.  
   If you plan to phase, set the option to phase in the job script (i.e. in the job script, where XGmix.py is called, set the <phase> option to TRUE   
   And adjust the amount of time alloted to complete this task (i.e. adjust the --time option to several hours)  


#### Reference panel building:  
   In the XGmix-master folder, there is a config.py file used to adjust parameter settings for XGmix. Take a look at this, consult the XGmix github for details.

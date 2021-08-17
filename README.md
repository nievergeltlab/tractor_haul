# Tractor HAUL
Implementation of Tractor local ancestry pipeline not relying on HAIL  
last rev Jan 15, 2021

## Prerequisites
Libraries:
- plink
- eagle
Other:
- Supercomputer with SLURM workload manager
- Directory containing 1000 genomes reference data in a folder named `1kg_hgdp`
- Working directory path assigned to `WORKING_DIR` variable and study name assigned to `study` variable in the .env file
- A txt file containing subjects to use as the reference panel from the 1000 genomes reference data in the `1kg_hgdp` folder, with the path assigned to `ref_subjects` in the .env file
- A .bed, .bim, .fam file containing genetic data of chromosomes 1-22 for the study, with the path and prefix assigned to `input_data` in the .env file (e.g. if your files are in /home/user/data and they are named mystudy.bed, mystudy.bim, mystudy.fam, then you would set `input_data=/home/user/data/mystudy`)

## Usage  
### 1) Edit .env
Set WORKING_DIR to directory to install xgmix and run the ancestry pipeline inside
  - this directory must have thousand genomes reference vcf's in the same build as the study data

### 2) Install XGmix
```
bash 00_xgmix_install.sh
```

### 3) Prepare for training

#### Split data file by chromosome
```
export $(cat .env | xargs); sbatch --array=1-22 --time=00:35:00 --error ${WORKING_DIR}/errandout/${study}/splitting/split_%a.e --output ${WORKING_DIR}/errandout/${study}/splitting/split_%a.o  --export=ALL,WORKING_DIR=$WORKING_DIR,study=$study  00a_split_by_chr.sh -D $WORKING_DIR
```

#### Phase chromosome vcf files
WAIT FOR ABOVE TO FINISH, then:
```
export $(cat .env | xargs); sbatch --array=1-22 --time=12:00:00 --error $WORKING_DIR/errandout/${study}/phasing/phase_%a.e --output $WORKING_DIR/errandout/${study}/phasing/phase_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  00b_phasing.sh -D $WORKING_DIR
```

#### Subset 1000 genomes reference data
```
bash 00c_subset_reference_panel.sh
```

### 4) Run training

#### Split each chromosome vcf into 50 mega-basepair blocks (with 5MB windows to preserve local ancestry prediction accuracy)
```
export $(cat .env | xargs); sbatch --array=1-22 --time=01:00:00 --error ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks_%a.e --output ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks%a.o  --export=ALL,WORKING_DIR=$WORKING_DIR,study=$study  01a_split_chr_into_blocks.sh -D $WORKING_DIR
```

#### Run training
```
bash 01b_train_xgmix_helper.sh
```

### 5) Run xgmix model local ancestry prediction
WAIT FOR TRAINING TO FINISH, then:
```
bash 02a_run_xgmix_helper.sh
```

### 6) Merge prediction results by chromosome, then expand and create ancestry covariate plink inputs

#### Merge predictions
WAIT FOR PREDICTION MODEL RUNNING TO FINISH, then:
```
bash 03a_merge_chr_blocks.sh
```

#### local ancestry expansion
```
export $(cat .env | xargs); sbatch --array=22 --time=12:00:00 --ntasks=1 --cpus-per-task=16 --error ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.e --output ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  03b_run_lanc_expansion.sh -D $WORKING_DIR
```

### 7) Plot local ancestry predictions
```
export $(cat .env | xargs); sbatch --time=12:00:00 --error ${WORKING_DIR}/errandout/${study}/plotting/plot_all.e --output ${WORKING_DIR}/errandout/${study}/plotting/plot_all.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  04a_run_lanc_plotting.sh -D $WORKING_DIR
```

### Other Usage Notes:  

The pipeline is a bit primitive, and for most will be a hackable example rather than a perfect out-of-the-box implementation

  A) jobs are not automatically resubmitted if failed.  
  B) There is no job dependency programmed in, you have to manually check if a job finished before proceeding to the next step  
  C) You will have to go into the job scripts to set certain paths

#### SLURM:
 This assumes that you have access to a SLURM computing system (eg LISA)

##### If you do not have SLURM:  
   Run the contents of the job script commands in the shell. Because chromosomes are by default indexed by the array index number, you will have to create a for loop to replace the array indexing variable. ie.

     for (SLURM_ARRAY_TASK_ID in seq 1 1 22) ; do ... job script contents ... ; done  ;  

   You'll also need to install whatever compiling libraries are necessary to install xgmix by yourself

   You also may need to use shorter blocks for splitting the chromosomes (eg 30 mega-basepairs) as xgmix uses a lot of memory

#### If you do not have HRC reference panel
   Specify your own reference panel in the phasing script. 1000G phase 3 is a good bet.

#### XGmix Phase correction:  
   Correcting phase dramatically increases computation time. Time scales up dramatically with the number of reference populations.  
   If you plan to phase, set the option to phase in the job script (i.e. in the job script, where XGmix.py is called, set the <phase> option to TRUE   
   And adjust the amount of time alloted to complete this task (i.e. adjust the --time option to several hours)  


#### Reference panel building:  
   In the XGmix-master folder, there is a config.py file used to adjust parameter settings for XGmix. Take a look at this, consult the XGmix github for details.

# Tractor HAUL
Implementation of Tractor local ancestry pipeline not relying on HAIL  
Revised Aug 17, 2021 - Michael

Uses [XGMix](https://github.com/AI-sandbox/XGMix) for local ancestry inference

## Prerequisites
Libraries:
- plink (1.9)
- plink2
- eagle
- shapeit

Note all of these libraries must be available in your path, they are all installed by `00_xgmix_install.sh`, but make sure to double check that installations worked properly

Other:
- Supercomputer with SLURM workload manager
- Working directory path assigned to `WORKING_DIR` variable and study name assigned to `study` variable in the .env file
- Directory containing reference data in a folder, with the path to the folder assigned to `REF_DIR` in the .env file, with reference data for each chromosome in files named as `refpanel_chr${CHR}.vcf.gz`, where ${CHR} is the chromosome number (1-22, this has not been tested on X)
- A txt file containing subjects to use as the reference panel from the reference data, with the path assigned to `ref_subjects` in the .env file
- A .bed, .bim, .fam file containing genetic data of chromosomes 1-22 for the study, with the path and prefix assigned to `input_data` in the .env file (e.g. if your files are in /home/user/data and they are named mystudy.bed, mystudy.bim, mystudy.fam, then you would set `input_data=/home/user/data/mystudy`)
- A .fam file, with phenotype information (could be the same file used from above, but with .fam extension), and column order [FID, IID, PAT, MAT, SEX, PHENO1] (no header), with the path assigned to `fam_file` in the .env file

## Usage  
### 1) Edit .env
- Set WORKING_DIR to the absolute path of the directory to run the ancestry pipeline inside
- Set REF_DIR to the absolute path of the directory with the reference VCF files, split by chromosome, with each file named `refpanel_chr${CHR}.vcf.gz`, where ${CHR} is the chromosome number (1-22, this has not been tested on X)
    - Note that these reference subjects should contain most of the SNPs contained in the sample data you plan to run local ancestry inference (LAI) on.

### 2) Install XGmix
```
bash 00_xgmix_install.sh
```

### 3) Prepare for training

#### Get ambiguous SNPs
```
bash 00a_get_ambiguous_snps.sh
```

#### Phase chromosome vcf files
```
export $(cat .env | xargs); sbatch --array=1-22 --time=12:00:00 --error $WORKING_DIR/errandout/${study}/phasing/phase_%a.e --output $WORKING_DIR/errandout/${study}/phasing/phase_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  00c_phasing.sh -D $WORKING_DIR
```

#### Subset 1000 genomes/HGDP reference data
```
bash 00c_subset_reference_panel.sh
```

### 4) Run training

#### Split each chromosome vcf into 50 mega-basepair blocks (with 5MB windows to preserve local ancestry prediction accuracy)
```
export $(cat .env | xargs); sbatch --array=1-22 --time=01:00:00 --error ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks_%a.e --output ${WORKING_DIR}/errandout/${study}/splitting/split_into_blocks%a.o  --export=ALL,WORKING_DIR=$WORKING_DIR,study=$study  01a_split_chr_into_blocks.sh -D $WORKING_DIR
```

- Note: this step will split each chromosome (both the study data and the reference data) into 50 megabase blocks, with 5 megabase buffers before and after the start/end positions. For example, the file named study_phased_chr1_50.vcf.gz will be used to predict the 50MB - 100MB block, but contains data from 45MB - 105MB in order to make sure the ancestry predictions for the areas around the 50MB/100MB ends stay relatively accurate

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

#### Clean directories of split data (to save disk space, because next step will use a lot of disk space)
```
bash 03b_clean_directories.sh
```

#### local ancestry expansion
```
export $(cat .env | xargs); sbatch --array=1-22 --time=12:00:00 --ntasks=1 --cpus-per-task=16 --error ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.e --output ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  03c_run_lanc_expansion.sh -D $WORKING_DIR
```

### 7) Plot local ancestry predictions
```
export $(cat .env | xargs); sbatch --time=12:00:00 --error ${WORKING_DIR}/errandout/${study}/plotting/plot_all.e --output ${WORKING_DIR}/errandout/${study}/plotting/plot_all.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  04a_run_lanc_plotting.sh -D $WORKING_DIR
```

### 8)) Run models with adjusted parameters to find best models
```
export $(cat .env | xargs); sbatch --time=2-12 --error ${WORKING_DIR}/errandout/${study}/changed_models/changed_models.e --output ${WORKING_DIR}/errandout/${study}/changed_models/changed_models.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR 05_run_changed_models.sh -D $WORKING_DIR
```

- Note this only runs on chromosome 22, then can compare resulting predictions files against each other to determine most fitting model (especially check that XGMix is not biasing towards EUR ancestry)

### 8) Run plink covariate (using ancestries) regression
```
export $(cat .env | xargs); sbatch --array=1-22 --time=24:00:00 --error ${WORKING_DIR}/errandout/${study}/regression/regression_%a.e --output ${WORKING_DIR}/errandout/${study}/regression/regression_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  06_run_plink_glm.sh -D $WORKING_DIR

```

## Other Usage Notes:  

The pipeline is a bit primitive, and for most will be a hackable example rather than a perfect out-of-the-box implementation

  A) jobs are not automatically resubmitted if failed.  
  B) There is no job dependency programmed in, you have to manually check if a job finished before proceeding to the next step  

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

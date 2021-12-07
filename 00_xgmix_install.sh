#!/bin/bash
# install libarchive dependency for xgmix
mkdir $HOME/libraries

# get env variables
export $(cat .env | xargs)

mkdir ${WORKING_DIR}/models # For trained models
mkdir ${WORKING_DIR}/predictions # For ancestry predictions
mkdir ${WORKING_DIR}/plots # For local ancestry karyoplots
mkdir ${WORKING_DIR}/recombination_maps # For recombination maps
mkdir ${WORKING_DIR}/lanc_expansion # For expanding output
mkdir ${WORKING_DIR}/plink_input # For plink input files
# data directories
mkdir -p ${WORKING_DIR}/${study}/phased
mkdir -p ${WORKING_DIR}/${study}/unphased
# error and output directories
mkdir -p ${WORKING_DIR}/errandout/${study}/phasing
mkdir -p ${WORKING_DIR}/errandout/${study}/splitting
mkdir -p ${WORKING_DIR}/errandout/${study}/training
mkdir -p ${WORKING_DIR}/errandout/${study}/running
mkdir -p ${WORKING_DIR}/errandout/${study}/expansion
mkdir -p ${WORKING_DIR}/errandout/${study}/changed_models
mkdir -p ${WORKING_DIR}/errandout/${study}/regression

echo "Installing libarchive..."
wget https://www.libarchive.org/downloads/libarchive-3.4.3.tar.gz
tar xvzf libarchive-3.4.3.tar.gz
cd libarchive-3.4.3
./configure --prefix=$HOME/libraries
make
make install

echo "Installing bcftools..."
cd ..
wget https://github.com/samtools/bcftools/releases/download/1.13/bcftools-1.13.tar.bz2
tar xvzf bcftools-1.13.tar.bz2
cd bcftools-1.13
./configure --prefix=$HOME/libraries
make
make install

echo "Installing plink..."
cd $HOME/libraries
mkdir bin
cd bin
wget https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20210606.zip
unzip plink_linux_x86_64_20210606.zip
rm plink_linux_x86_64_20210606.zip
export PATH=$PATH:$HOME/libraries/bin

echo "Installing plink2..."
wget https://s3.amazonaws.com/plink2-assets/alpha2/plink2_linux_x86_64.zip
unzip plink2_linux_x86_64.zip
rm plink2_linux_x86_64.zip

echo "Instaling shapeit v2..."
wget https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.v2.r904.glibcv2.17.linux.tar.gz
tar -xzf shapeit.v2.r904.glibcv2.17.linux.tar.gz
mv shapeit.v2.904.3.10.0-693.11.6.el7.x86_64/bin/shapeit .
rm shapeit.v2.r904.glibcv2.17.linux.tar.gz
rm -r shapeit.v2.904.3.10.0-693.11.6.el7.x86_64

# call into working dir
cd $WORKING_DIR

# INSTALLATION

# Run this command so it knows to look for libarchive here.
LD_LIBRARY_PATH=$HOME/libraries/lib:$LD_LIBRARY_PATH

# Load python and MPI modules.
module load 2020
# module load CMake/3.16.4-GCCcore-9.3.0 if xgboost install is failing
module load OpenMPI/4.0.3-GCC-9.3.0
module load Python/3.8.2-GCCcore-9.3.0

# Download XGmix
wget https://github.com/AI-sandbox/XGMix/archive/master.zip
unzip master.zip

cd XGMix-master

# Backup config
cp config.py config-backup.py

# Need to add seaborn==0.11.0 to the requirements.txt
echo "seaborn==0.11.0" >> requirements.txt

# Install required python modules
pip install -r requirements.txt --user

# You must comment out two lines of code from the code for XGmix, it is for plotting a confusion matrix. Not compatible with LISA..
# /home/pgca1pts/ancestry/XGMix-master/Utils/visualization.py

# comment out the following lines by putting hash tags (#) before the line starts. They should be lines 19 and 20:
#   cm_figure = plot_cm(cm, normalize=True, labels=labels)
#   cm_figure.figure.savefig(save_path+"/confusion_matrix_normalized.png")

# If all did not have errors, XGmix should now work!

# Install program for plotting local ancestry
module load 2020
module load R

cd $WORKING_DIR
echo '
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
Y
BiocManager::install("karyoploteR")
q("no")
' > install.R
Rscript install.R
rm install.R

#install libarchive dependency for xgmix
 mkdir /home/czai/libraries
 
 wget https://www.libarchive.org/downloads/libarchive-3.4.3.tar.gz
 tar xvzf libarchive 
 cd libarchive-3.4.3
 ./configure --prefix=/home/czai/libraries
 make
 make install
 
#Make a directory where the analysis will go
WORKING_DIR=
mkdir $WORKING_DIR

#call into it
cd $WORKING_DIR

#INSTALLATION 

#Run this command so it knows to look for libarchive here. 
 LD_LIBRARY_PATH=/home/czai/libraries/lib:$LD_LIBRARY_PATH

#Load python and MPI modules. 
 module load 2019
 module load OpenMPI/3.1.4-GCC-8.3.0
 module load Python/3.6.6-intel-2019b
 #May need CMAKE GCC -  module load Boost.Python/1.72.0-gompi-2020a  CMake/3.16.4-GCCcore-9.3.0

#Download XGmix
 wget https://github.com/AI-sandbox/XGMix/archive/master.zip
 unzip master.zip
 
 cd XGMix-master

#Install required python modules
 pip install -r requirements.txt --user

#You must comment out two lines of code from the code for XGmix, it is for plotting a confusion matrix. Not compatible with LISA..
/home/czai/ancestry/XGMix-master/Utils/visualization.py

comment out the following lines by putting hash tags (#) before the line starts. They should be lines 19 and 20:
     cm_figure = plot_cm(cm, normalize=True, labels=labels) 
     cm_figure.figure.savefig(save_path+"/confusion_matrix_normalized.png") 

#If all did not have errors, XGmix should now work!

#Install program for plotting local ancestry
module load 2019
module load R
R
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
Y
BiocManager::install("karyoploteR")
q("no")

#install BCFtools
#SEE INSTRUCTIONS ON
#http://www.htslib.org/download/

#You'll also need some directories to store files 

cd $WORKING_DIR

mkdir "$WORKING_DIR"/temp #For temporary files
mkdir "$WORKING_DIR"/refpanels #For reference panels
mkdir "$WORKING_DIR"/recombination_maps #For recombination maps

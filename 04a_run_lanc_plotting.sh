#!/bin/bash
Rscript 04_lanc_plotting.r $WORKING_DIR $study
# sbatch --time=12:00:00 --error ${WORKING_DIR}/errandout/${study}/plotting/plot_all.e --output ${WORKING_DIR}/errandout/${study}/plotting/plot_all.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  04a_run_lanc_plotting.sh -D $WORKING_DIR

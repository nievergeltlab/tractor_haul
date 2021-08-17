#!/bin/bash
# get WORKING_DIR and study variables
export $(cat .env | xargs)
lens=(249 242 198 190 182 170 159 145 138 134 135 133 114 107 102 90 83 80 59 64 47 51)
for chr in {1..22}; do
  len=$(( ${lens[chr-1]} + 1 ))
  for ((i = 0; i < len; i += 50)); do
    sbatch --time=12:00:00 --error ${WORKING_DIR}/errandout/${study}/training/train_${chr}_${i}.e --output ${WORKING_DIR}/errandout/${study}/training/train_${chr}_${i}.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR,chr=$chr,begin=$i  01_train_xgmix.sh -D $WORKING_DIR
  done
done

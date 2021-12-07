#!/bin/bash
cd ${WORKING_DIR}/scripts
for config_file in $(ls model_config); do
  run_name=${config_file%.py}
  echo "Running $run_name"
  mkdir -p ${WORKING_DIR}/changed_models/${run_name}
  mkdir -p ${WORKING_DIR}/changed_models/${run_name}/models
  mkdir -p ${WORKING_DIR}/changed_models/${run_name}/predictions
  cp model_config/$config_file ${WORKING_DIR}/XGMix-master/config.py

  # Run training
  ./01b_train_xgmix_helper.sh
  running=$(squeue --me | grep "01_train")
  while [[ $running != "" ]]; do
    sleep 1m
    running=$(squeue --me | grep "01_train")
  done

  # Run predictions
  ./02a_run_xgmix_helper.sh
  running=$(squeue --me | grep "02_run")
  while [[ $running != "" ]]; do
    sleep 1m
    running=$(squeue --me | grep "02_run")
  done

  # Merge predictions and copy to changed_models directory
  ./03a_merge_chr_blocks.sh
  cp -r ${WORKING_DIR}/models/${study}/22_0 ${WORKING_DIR}/changed_models/${run_name}/models
  cp -r ${WORKING_DIR}/models/${study}/22_50 ${WORKING_DIR}/changed_models/${run_name}/models
  cp -r ${WORKING_DIR}/predictions/${study}/22 ${WORKING_DIR}/changed_models/${run_name}/predictions
done

# export $(cat .env | xargs); sbatch --time=2-12 --error ${WORKING_DIR}/errandout/${study}/changed_models/changed_models.e --output ${WORKING_DIR}/errandout/${study}/changed_models/changed_models.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR 05_run_changed_models.sh -D $WORKING_DIR

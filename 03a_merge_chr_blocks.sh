#!/bin/bash
# merge 50 MB blocks into final predictions file for each chromosome
# get env variables
export $(cat .env | xargs)
# chromosome lengths in mega-basepairs
lens=(249 242 198 190 182 170 159 145 138 134 135 133 114 107 102 90 83 80 59 64 47 51)
for chr in {1..22}; do
  mkdir -p $WORKING_DIR/predictions/$study/$chr
  outfile=$WORKING_DIR/predictions/$study/$chr/${study}_${chr}.msp.tsv
  head -n 2 $WORKING_DIR/predictions/$study/${chr}_0/${study}_${chr}_0.msp.tsv | tail -n 1 > $outfile
  len=$(( ${lens[chr-1]} + 1 ))
  for ((i = 0; i <= len; i += 50)); do
    end=$(( i + 50 ))
    file=$WORKING_DIR/predictions/$study/${chr}_${i}/${study}_${chr}_${i}.msp.tsv
    # Get rid of the 5MB windows (windows were used to make sure local ancestry predictions at either end were accurate)
    awk -v begin=$i -v end=$end '{ if(NR<=2){ next } else if($2 >= begin * 1e6 && $2 < end * 1e6){ print } else if($2 >= end * 1e6){ exit } }' $file >> $outfile
  done
done

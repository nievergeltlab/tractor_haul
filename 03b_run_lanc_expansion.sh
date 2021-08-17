#!/bin/bash
LANC_DIR=$WORKING_DIR/lanc_expansion
chr=$SLURM_ARRAY_TASK_ID

# make directories
mkdir -p $LANC_DIR/haplotypes/${study}/${chr}
mkdir -p $LANC_DIR/predictions/${study}/${chr}
mkdir -p $LANC_DIR/indicators/${study}/${chr}
mkdir -p $LANC_DIR/lanctotals/${study}/${chr}
mkdir -p $LANC_DIR/plink_output/${study}/${chr}

#-----------------------------------------------------
#-----------split subject data by haplotype-----------
#-----------------------------------------------------

datafile=$WORKING_DIR/${study}/phased/${study}_phased_chr${chr}.vcf.gz
headerline=$(zcat $datafile | head -n 20 | awk '{if(/^##/){next} else if(/^#/){print NR} }')

# get header line, remove # from #CHROM
zcat $datafile | tail -n+$(( headerline + 1 )) > $TMPDIR/${study}_phased_chr${chr}.vcf.haps
zcat $datafile | head -n${headerline} | tail -n1 | sed 's/#//g' | awk 'BEGIN{OFS="\t"}{$1=$1; print}'  >  $TMPDIR/${study}_phased_chr${chr}.vcf.haps.header

# split into 16 processes (I chose 16 since my local desktop has 16 threads so can run this both on LISA and locally)
datafile=$TMPDIR/${study}_phased_chr${chr}.vcf.haps
threads=8
# threads=$(( SLURM_JOB_NUM_NODES * SLURM_CPUS_ON_NODE / 2 ))
lines_per_thread=$(wc -l $datafile | awk -v threads=$threads '{printf("%.0f\n", $0 / threads + 1)}')
pidarr=()
# split file 8 times, create hap0 and hap1 file for each subset, then recombine
for i in $(seq 1 $threads); do
  partfile=$TMPDIR/${study}_phased_chr${chr}_${i}.vcf.haps
  begin=$(( ( i - 1 ) * lines_per_thread ))
  awk -v begin=$begin -v lines_per_thread=$lines_per_thread 'BEGIN{OFS="\t"} {if(NR >= begin && NR < begin + lines_per_thread) { print } }' $datafile > $partfile
  (awk 'BEGIN{OFS="\t"; FS="\t"} { for(i=10; i<=NF; i++) {$i = substr ($i, 1, 1)} } 1' $partfile > \
    $TMPDIR/${study}_${chr}_${i}.hap0.tsv) &
  pidarr+=("$!")
  (awk 'BEGIN{OFS="\t"; FS="\t"} { for(i=10; i<=NF; i++) {$i = substr ($i, 3, 1)} } 1' $partfile > \
    $TMPDIR/${study}_${chr}_${i}.hap1.tsv) &
  pidarr+=("$!")
done

# pause script until all sections finish
running=true
echo
while [ "$running" = true ]; do
  running=false
  for pid in "${pidarr[@]}"; do
    if [ -d "/proc/${pid}" ]; then
      running=true
    fi
  done
  echo -ne "\rSplitting haplotypes: $running"
  sleep 10s
done
echo

# combine all parts into one
hap0file=$LANC_DIR/haplotypes/${study}/${chr}/${study}_${chr}.hap0.tsv
hap1file=$LANC_DIR/haplotypes/${study}/${chr}/${study}_${chr}.hap1.tsv
headerfile=$TMPDIR/${study}_phased_chr${chr}.vcf.haps.header
cp $headerfile $hap0file
cp $headerfile $hap1file
for i in $(seq 1 $threads); do
  cat $TMPDIR/${study}_${chr}_${i}.hap0.tsv >> $hap0file
  cat $TMPDIR/${study}_${chr}_${i}.hap1.tsv >> $hap1file
done

#-----------------------------------------------------------------
#-----------split ancestry prediction data by haplotype-----------
#-----------------------------------------------------------------

datafile=$WORKING_DIR/predictions/${study}/${chr}/${study}_${chr}.msp.tsv
headerline=2

# get header line, remove # from #CHROM
tail -n+$(( headerline + 1 )) $datafile > $TMPDIR/${study}_${chr}.msp.tsv.data
head -n${headerline}  $datafile | tail -n1 | sed 's/#//g;s/n snps/nsnps/g' | awk 'BEGIN{OFS="\t"}{ for(i=8; i<=NF; i+=2) {$i = ""} } 1'  >  $TMPDIR/${study}_${chr}.hap0.msp.tsv.header
head -n${headerline}  $datafile | tail -n1 | sed 's/#//g;s/n snps/nsnps/g' | awk 'BEGIN{OFS="\t"}{ for(i=7; i<=NF; i+=2) {$i = ""} } 1'  >  $TMPDIR/${study}_${chr}.hap1.msp.tsv.header


# split into 16 processes
datafile=$TMPDIR/${study}_${chr}.msp.tsv.data
cp $datafile $WORKING_DIR/tmp
threads=8
# threads=$(( SLURM_JOB_NUM_NODES * SLURM_CPUS_ON_NODE / 2 ))
lines_per_thread=$(wc -l $datafile | awk -v threads=$threads '{printf("%.0f\n", $0 / threads + 1)}')
pidarr=()
# split file 8 times, create hap0 and hap1 file for each subset, then recombine
for i in $(seq 1 $threads); do
  partfile=$TMPDIR/${study}_${chr}_${i}.msp.tsv
  begin=$(( ( i - 1 ) * lines_per_thread ))
  awk -v begin=$begin -v lines_per_thread=$lines_per_thread 'BEGIN{OFS="\t"} {if(NR >= begin && NR < begin + lines_per_thread) { print } }' $datafile > $partfile
  cp $partfile $WORKING_DIR/tmp
  (awk 'BEGIN{OFS="\t"} { for(i=8; i<=NF; i+=2) {$i = ""} } 1' $partfile > \
    $TMPDIR/${study}_${chr}_${i}.hap0.msp.tsv) &
  pidarr+=("$!")
  (awk 'BEGIN{OFS="\t"} { for(i=7; i<=NF; i+=2) {$i = ""} } 1' $partfile > \
    $TMPDIR/${study}_${chr}_${i}.hap1.msp.tsv) &
  pidarr+=("$!")
done

# pause script until all sections finish
running=true
while [ "$running" = true ]; do
  running=false
  for pid in "${pidarr[@]}"; do
    if [ -d "/proc/${pid}" ]; then
      running=true
    fi
  done
  echo -ne "\rSplitting ancestry predictions: $running"
  sleep 10s
done
echo

# combine all parts into one
hap0file=$LANC_DIR/predictions/${study}/${chr}/${study}_${chr}.hap0.msp.tsv
hap1file=$LANC_DIR/predictions/${study}/${chr}/${study}_${chr}.hap1.msp.tsv
hap0headerfile=$TMPDIR/${study}_${chr}.hap0.msp.tsv.header
hap1headerfile=$TMPDIR/${study}_${chr}.hap1.msp.tsv.header
cp $hap0headerfile $hap0file
cp $hap1headerfile $hap1file
for i in $(seq 1 $threads); do
  cat $TMPDIR/${study}_${chr}_${i}.hap0.msp.tsv >> $hap0file
  cat $TMPDIR/${study}_${chr}_${i}.hap1.msp.tsv >> $hap1file
done

#--------------------------------------------------
#-----------generate european indicators-----------
#--------------------------------------------------
lancfile=$LANC_DIR/predictions/${study}/${chr}/${study}_${chr}
awk 'BEGIN{OFS="\t"}{if (NR > 1) { for(i=7;i<NF;i++){ $i=($i==2) } } }1' $lancfile.hap0.msp.tsv > \
  $LANC_DIR/indicators/${study}/${chr}/${study}_${chr}.anc2.hap0.msp.tsv
awk 'BEGIN{OFS="\t"}{if (NR > 1) { for(i=7;i<NF;i++){ $i=($i==2) } } }1' $lancfile.hap1.msp.tsv > \
  $LANC_DIR/indicators/${study}/${chr}/${study}_${chr}.anc2.hap1.msp.tsv

#----------------------------------------------------------------------
#-----------generate african & american covariate indicators-----------
#----------------------------------------------------------------------
awk 'BEGIN{OFS="\t"}{if (NR > 1) { for(i=7;i<NF;i++){ $i=($i==0 || $i==1) } } }1' $lancfile.hap0.msp.tsv > \
  $LANC_DIR/indicators/${study}/${chr}/${study}_${chr}.anc0.anc1.hap0.msp.tsv
awk 'BEGIN{OFS="\t"}{if (NR > 1) { for(i=7;i<NF;i++){ $i=($i==0 || $i==1) } } }1' $lancfile.hap1.msp.tsv > \
  $LANC_DIR/indicators/${study}/${chr}/${study}_${chr}.anc0.anc1.hap1.msp.tsv

# local ancestry calculation
python3 03_lanc_expansion.py ${WORKING_DIR} ${study} ${chr}

#run plink
# plink2 --import-dosage ${LANC_DIR}/lanctotals/${study}/${chr}/${study}_${chr_num}.total.anc2.msp.tsv format=1 noheader \
#  --fam ${WORKING_DIR}/pts_mrsc_mix_am-qc.fam  --glm local-covar=${LANC_DIR}/lanctotals/${study}/${chr}/${study}_${chr_num}.total.anc0.anc1.msp.tsv \
#  local-pos-cols=1,2,3,6 --out ${LANC_DIR}/plink_output/${study}/${chr}/${study}_${chr}_lanc

# export $(cat .env | xargs); sbatch --array=22 --time=12:00:00 --ntasks=1 --cpus-per-task=16 --error ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.e --output ${WORKING_DIR}/errandout/${study}/expansion/lanc_expansion_%a.o  --export=ALL,study=$study,WORKING_DIR=$WORKING_DIR  03b_run_lanc_expansion.sh -D $WORKING_DIR

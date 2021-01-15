#!/bin/bash

#Script does the following:
#Convert unphased BED to unphased VCF format. 
 #Only well imputed (98% genotyped) markers are included.
 #Ambiguous markers are excluded!
#Index VCF file with tabix

for chr in {1..22} 
 do 
 $plinkpath --bfile $bfile --chr $chr --geno 0.02 --exclude $ambiguous --recode-vcf --out temp/"$study"_chr$chr
 bgzip -c temp/"$study"_chr"$chr".vcf > temp/"$study"_chr"$chr".vcf.gz
 tabix -p vcf temp/"$study"_chr"$chr".vcf.gz
 rm  temp/"$study"_chr$chr.vcf
 done
 
 
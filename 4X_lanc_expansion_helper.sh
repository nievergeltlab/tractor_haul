#Do a kcolumn split of local ancestry
#Do a delimiting of | then kcolumn split of haplotypes vcf

#Need to adjust this to be able to add the UNKINKED data!

 zcat "$study"/phased/"$study"_phased_chr22.vcf.gz | tail -n+11 | sed 's/|/\t/g' > temp/"$study"_phased_chr22.vcf.haps
 zcat "$study"/phased/"$study"_phased_chr22.vcf.gz  | head -n10 | tail -n1   | sed 's/#//g' | awk '{$1=$1; print}'  >  temp/"$study"_phased_chr22.vcf.haps.header 
 
 ##Notice that I am filtering | and \, these are the phased and unphased designations for SNPs in VCF format. In case there are a few unphased, for whatever reason, just act as if they are phased.
 
 #use tr -s ' ' to get rid of the stupid fucking padding spaces if they exist
#Notice that the odd/even selection REMOVES the columns, rather than selecting them, hence the file names are haps1 and haps0
#Make sure that the phased data starts at columm 9 and beyond
awk '{ for (i=10;i<=NF;i+=2)  $i="" } 1' temp/"$study"_phased_chr22.vcf.haps | sed 's/|/\t/g' | sed 's/\//\t/g' | cat temp/"$study"_phased_chr22.vcf.haps.header - > temp/"$study"_phased_chr22.vcf.haps1
awk '{ for (i=11;i<=NF;i+=2)  $i="" } 1' temp/"$study"_phased_chr22.vcf.haps | sed 's/|/\t/g' | sed 's/\//\t/g' | cat temp/"$study"_phased_chr22.vcf.haps.header - > temp/"$study"_phased_chr22.vcf.haps0


#In R, the easiest thing to do will be to append the trailing .0 and .1 on subject names to account for the haps names.
#note I use sed to change 'n snps' coluimn name to get rid of the dumb space delimiter
 awk '{ for (i=7;i<=NF;i+=2) $i=""  } 1' GTP.rfmix.chr22.msp.tsv | sed 's/n snps/nsnps/g' | sed 's/#//g'  | tail -n+1 > GTP.rfmix.chr22.msp.tsv.lanc1
 awk '{ for (i=8;i<=NF;i+=2) $i=""  } 1' GTP.rfmix.chr22.msp.tsv | sed 's/n snps/nsnps/g' | sed 's/#//g' | tail -n+1 > GTP.rfmix.chr22.msp.tsv.lanc0

Rscript 4X_lanc_expansion.R
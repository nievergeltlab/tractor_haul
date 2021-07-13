#All subjects in reference panel file must be described in the populations origins file

#This means that ONLY the subjects who you want to be references should be in the reference file!

for chr in 21 # {1..20}
do
 /home/czai/libraries/bcftools/bin/bcftools view -Oz -S /home/czai/ancestry/1kg_hgdp/pgcptsdrefpops.subjects /home/czai/ancestry/1kg_hgdp/1kg_hgdp_short_chr"$chr".vcf.gz > /home/czai/ancestry/1kg_hgdp/1kg_hgdp_refpanel_chr"$chr".vcf.gz
 done
 
 zcat /home/czai/ancestry/1kg_hgdp/1kg_hgdp_refpanel_chr"$chr".vcf.gz | awk '{gsub(/^chr/,""); print}'  | gzip > /home/czai/ancestry/1kg_hgdp/1kg_hgdp_refpanel_chr"$chr".vcf.gz2

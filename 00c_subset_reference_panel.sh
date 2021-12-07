#All subjects in reference panel file must be described in the populations origins file
#This means that ONLY the subjects who you want to be references should be in the reference file!

# get env variables
export $(cat .env | xargs)
for chr in {1..22}
do
  bcftools view -Oz -S $ref_subjects ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz > ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz
  done

  #Example code: If you really don't want the chr prefix on your reference data:
  zcat ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz | awk '{gsub(/^chr/,""); print}'  | gzip > ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz2
  mv ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz2 ${WORKING_DIR}/${REF_DIR}/refpanel_chr${chr}.vcf.gz

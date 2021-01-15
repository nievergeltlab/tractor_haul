 library(data.table)
 library(wrapr)
 library(speedglm)
 #Load covariate data sheets
  study <- args[1] 
  columns_to_exclude <- args[2] #set a variable to exclude first N columns, in case the phased output I use differs accross files
  fam <- fread(paste(study,'_bg_cobg.fam',sep=''),data.table=F)
  names(fam) <- c("FID","IID","M","F","G","P")
  covariate <- fread(pca_filename,data.table=F) 
  covs <- merge(fam,covariate,by=c("FID","IID"))
   
 #Load haps
  haps0 <- fread('gtpc_phased_chr22.vcf.haps0',data.table=F)
  haps1 <- fread('gtpc_phased_chr22.vcf.haps1',data.table=F)
 #append the .0 to the hap names to match the lanc files
  #columns 1:X are excluded because those are just XGmix outputs.
  names(haps0)[-c(1:columns_to_exclude)] <- paste(names(haps0)[-c(1:columns_to_exclude)],".0",sep='') 
  names(haps1)[-c(1:columns_to_exclude)] <- paste(names(haps1)[-c(1:columns_to_exclude)],".1",sep='') 
  
  
  row.names(haps0) <- haps0$ID
  row.names(haps1) <- haps1$ID
 
 #make this just a matrix for processing speed!
  haps0a <- as.matrix(haps0[,-c(1:columns_to_exclude)])
  haps1a <- as.matrix(haps1[,-c(1:columns_to_exclude)])
  
  #can't remove unaltered haps matrix yet to save ram because the position is utilized in intervals. save as a variable to allow for memory saving
   
 #Load LANC
  lanc0 <- fread('GTP.rfmix.chr22.msp.tsv.lanc0',data.table=F)
  lanc1 <- fread('GTP.rfmix.chr22.msp.tsv.lanc1',data.table=F)
  
 #Convert local ancestry to sign values for calculating number of effect alleles. For greater than 2 ancestries, just add more equivalences (e.g. ..._anc2 == 2, ..._anc3 ==3 and so on)
 
  eqcheck <- function(x,eqval=0)
  {
   as.numeric(x == eqval)
  }
  
  lanc0_anc0 <- as.matrix(apply(lanc0[,c(7:ncol(lanc0))],c(1,2),eqcheck,eqval=0))
  lanc1_anc0 <- as.matrix(apply(lanc1[,c(7:ncol(lanc1))],c(1,2),eqcheck,eqval=0))

  lanc0_anc1 <- as.matrix(apply(lanc0[,c(7:ncol(lanc0))],c(1,2),eqcheck,eqval=1))
  lanc1_anc1 <- as.matrix(apply(lanc1[,c(7:ncol(lanc1))],c(1,2),eqcheck,eqval=1))
  
  #


 #Expand the local ancestry matrices so they conform to dimension of haplotypes (i.e. assign local ancestry to every SNP)
  intervals <- findInterval(haps0$POS, lanc0$epos,rightmost.closed=TRUE) + 1 #The +1 is because intervals bins start from 0. Also note how the right intervals is closed to account for end of chromsoome SNPS, which would otherwise be assigned to a non-existing interval..

 #The haps matrices are identical in dimension by construction. So this interval finding only needs to be done for one matrix. 
 #I do it for both just in case for testing purposes
  lanc0_anc0_expanded <- lanc0_anc0[intervals,]
  lanc1_anc0_expanded <- lanc1_anc0[intervals,]

  lanc0_anc1_expanded <- lanc0_anc1[intervals,]
  lanc1_anc1_expanded <- lanc1_anc1[intervals,]

  save(lanc0_anc0_expanded,lanc1_anc0_expanded,file="GTP.rfmix.chr22.msp.tsv.lanc0.anc0.R",quote=F,row.names=F)
  save(lanc0_anc1_expanded,lanc1_anc1_expanded,file="GTP.rfmix.chr22.msp.tsv.lanc.anc1.R",quote=F,row.names=F)
  save(haps0a,haps1a,file="GTP.rfmix.chr22.msp.tsv.haps.R",quote=F,row.names=F)

  
#Currently only coded for 0/1, but expansible to 3...

#at this point I should switch the data format to matrices to speed things up!

#N copies of risk allele for ancestry 0
 hap0_anc0 <- lanc0_anc0_expanded * haps0a
 hap1_anc0 <- lanc1_anc0_expanded * haps1a
 
 anc0_ncopies <- hap0_anc0 + hap1_anc0

#N copies of risk allele for ancestry 1
 hap0_anc1 <- lanc0_anc1_expanded * haps0[,c(10:ncol(haps0))] 
 hap1_anc1 <- lanc1_anc1_expanded * haps1[,c(10:ncol(haps0))] 

 anc1_ncopies <- hap0_anc1 + hap1_anc1

#And so on for N groups > 2...

#Now have matrices where each row is a SNP and each column is a subject. Need to transpose to make this usable.

 anc0_ncopies_t <- t(anc0_ncopies)
 anc1_ncopies_t <- t(anc1_ncopies)
 
#Now each row is a subject and column is a SNP. this can now be mated with the phenotype/covariate file
 p <- match_order(d2$idx, d1$idx)
 
#You may want to get rid of the stretches where N snps = 0!!

args <- commandArgs(trailingOnly = TRUE)
#reference data file name
studylanc <- args[1]
outdir <- args[2]

library(data.table)
library(karyoploteR)
library(plyr)

#Load all local ancestry calls
for (i in c(1:22))
{
	assign(
		paste("chr_",i,sep=""), 
   fread(paste(studylanc,"_",i,".msp.tsv",sep=""),data.table=F)
		) 
}

#parse the text list of data frame names as a list of data frames
data_list <- eval( 
			parse( 
				text=paste(
					"list(", paste(
       paste(paste("chr","_",c(1:22),sep=""))
      , collapse=','), ")" 
					)
				)
			)
   
#Stack all ancestry calls together using rbind.fill
DM <- rbind.fill (data_list)

#Count number of subjects
nsub=(dim(DM)[2] -6) /2 

#note where the switch areas are
 hap_switches <- toGRanges(data.frame(chr=paste("chr",DM[,1],sep=""), start=DM$spos, end=DM$epos))


for (subj in 1:nsub)
{
 pdf(file=paste(outdir,"/",names(DM)[7 + (subj-1)*2 ],"_",names(DM)[8 + (subj-1)*2 ],".pdf",sep=""),7,7)
#For each subject make a Karyogram
 kp <- plotKaryotype(chromosomes=c("autosomal"),plot.type="2")

#Color the switches based on LANC
 kpPlotRegions(kp, hap_switches, col=DM[,7 + (subj-1)*2 ] +1, data.panel = 1) #The +1 is to make it so the color index starts at black
 kpPlotRegions(kp, hap_switches, col=DM[,8 + (subj-1)*2 ] +1, data.panel = 2) #(subj-1)*2 controls the indexing because every adjacent pair columns is a subject. Subject oclumns start at 7
 dev.off()
 }
 
##Colors info:
#The color coding is indexed in a lazy way, where I just picked the first colors in the ordered list from R
#Colors are:
# 1 black 
# 2 red
# 3 green
# 4 blue
# 5 light blue
# 6 pink
# 7 yellow
# 8 grey

#So in plotting, the first ancestry (coded 0) in the msp.tsv files will be colored black, the second (coded 1) colored red, and so on.



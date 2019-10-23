#!/usr/bin/env R

require(gplots)
require(viridisLite)

args <- commandArgs(trailingOnly=T)
file <- tools::file_path_sans_ext(basename(args[1]))
dir <- dirname(args[1])

data <- read.table(args[1], header=T, comment.char='')

if(nrow(data) > 0) {

    pdf(paste(dir,"/",file,"_Heatmap.pdf",sep=""))

    heatmap.2(as.matrix(data), hclustfun=function(x)
    hclust(x,method='ward.D2'), Colv=T, Rowv=T, col=viridis(100), scale='none', trace='none', key=TRUE, density.info='none', dendrogram='col', labRow=F, cexCol=0.8, margins=c(12,8), srtCol=45)

    dev.off()
    
}
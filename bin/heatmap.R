#!/usr/bin/env R

require(gplots)
require(viridisLite)

args <- commandArgs(trailingOnly=T)
file <- tools::file_path_sans_ext(basename(args[1]))
dir <- dirname(args[1])

data <- read.table(args[1], header=T, na.strings = "NA", comment.char='')

if(nrow(data) > 0) {

    if (0.25*ncol(data) < 6) {
        dims <- 6
    } else {
        dims <- 0.25*ncol(data)
    }

    pdf(paste(dir,"/",file,"_Heatmap.pdf",sep=""), height=8, width=dims)

    heatmap.2(as.matrix(data), na.color = "white", hclustfun=function(x)
    hclust(x,method='ward.D2'), Colv=T, Rowv=T, col=viridis(100), scale='none', trace='none', key=TRUE, density.info='none', dendrogram='col', labRow=F, cexCol=0.8, margins=c(12,8), srtCol=45)

    dev.off()
    
}
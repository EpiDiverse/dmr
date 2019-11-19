#!/usr/bin/env R

require(ggplot2)
require(viridisLite)

args <- commandArgs(trailingOnly=T)
file <- tools::file_path_sans_ext(basename(args[1]))
dir <- dirname(args[1])

data <- read.table(args[1], col.names=c('DMR', 'CpN', 'difference', 'length'))
cbPalette <- viridis(2,alpha=0.7,begin=0.5,end=1,option="E")


### Piechart Distribution

hyper_count <- nrow(subset(data, DMR=="hypermethylated"))
hypo_count <- nrow(subset(data, DMR=="hypomethylated"))

count <- data.frame(DMR=c('hypomethylated','hypermethylated'), counts=c(hypo_count, hyper_count))
count$prop <- round((count$counts/sum(count$counts))*100,1)
count$ypos <- cumsum(count$prop) - 0.5*count$prop

pdf(paste(dir,"/",file,"_Piechart.pdf",sep=""))

ggplot(count, aes(x=factor(1), fill=DMR, y=prop), alpha=0.4) +
    geom_bar(width=1, stat='identity', size=10) +
    #geom_text(aes(x=factor(1), y=(counts/2), label=counts), size=5) +
    geom_text(aes(y = ypos, label = counts)) +
    #coord_polar(theta='y') +
    coord_polar("y", start = 0)+
    theme_bw() +
    scale_fill_manual(values=cbPalette) +
    scale_color_manual(values=cbPalette) +
    theme(axis.title.x=element_blank(), axis.ticks.x=element_blank(), axis.text.x=element_blank()) +
    theme(axis.title.y=element_blank(), axis.ticks.y=element_blank(), axis.text.y=element_blank()) +
    theme(panel.background=element_blank(), panel.grid.major=element_line(color="grey"), panel.grid.minor=element_line(color="lightgrey")) + 
    xlab('') +
    ylab('')

dev.off()


### Methylation Level Distribution
pdf(paste(dir,"/",file,"_DensDiff.pdf",sep=""))

ggplot(data, aes(difference, group=DMR, fill=DMR, color=DMR)) +
    geom_density(alpha=0.4) + xlim(-1,1) +
    theme_bw() +
    theme(panel.background=element_blank()) +
    theme(axis.line.x=element_line(color="grey"), axis.line.y=element_line(color="grey")) +
    scale_fill_manual(values=cbPalette) +
    scale_color_manual(values=cbPalette) +
    xlab('methylation difference [relative prop.]')

dev.off()


### DMR Length Distribution
pdf(paste(dir,"/",file,"_DensLen.pdf",sep=""))

ggplot(data, aes(length, color=DMR, fill=DMR, color=DMR)) +
    geom_density(alpha=0.5) + xlim(range(data$length)) +
    theme_bw() +
    theme(panel.background=element_blank()) +
    theme(axis.line.x=element_line(color="grey"), axis.line.y=element_line(color="grey")) +
    scale_fill_manual(values=cbPalette) +
    scale_color_manual(values=cbPalette) +
    xlab('length [nt]')

dev.off()



### CpN Distribution
pdf(paste(dir,"/",file,"_DensCpN.pdf",sep=""))

ggplot(data, aes(CpN, color=DMR, fill=DMR, color=DMR)) +
    geom_density(alpha=0.5) +
    theme_bw() +
    theme(panel.background=element_blank()) +
    theme(axis.line.x=element_line(color="grey"), axis.line.y=element_line(color="grey")) +
    scale_fill_manual(values=cbPalette) +
    scale_color_manual(values=cbPalette) +
    xlab('CpN [#]')

dev.off()

### 
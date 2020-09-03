#!/usr/bin/env nextflow


// taking input bedGraph files and preprocessing into bed format
process "preprocessing" {

    label "low"
    tag "$context - $sample"

    maxForks "${params.fork}".toInteger()

    input:
    tuple val(context), val(sample), path(bedGraph), val(group), val(replicate)
    // eg. [CpG, TA_XX_NN_NN_X_YYMMDD_X_1, /path/to/TA_XX_NN_NN_X_YYMMDD_X_1_CpG.bedGraph, group1, rep1]

    output:
    tuple val(context), val(sample), path("${group}_${replicate}.bed")
    // eg. [CpG, TA_XX_NN_NN_X_YYMMDD_X_1, /path/to/group1_rep1.bed]

    script:
    """
    tail -n+2 ${bedGraph} | 
    awk 'BEGIN{OFS="\\t"} {if((\$5+\$6)>${params.cov}) 
    {printf "%s\\t%s\\t%s\\t%1.2f\\n", \$1,\$2,\$3,(\$4/100)}}' \\
    > ${group}_${replicate}.bed
    """

}


// combining samples into metilene input format according to each pairwise comparison
process "bedtools_unionbedg" {

    label "low"
    tag "${context} - ${group1}_vs_${group2}"

    maxForks "${params.fork}".toInteger()
    publishDir "${params.output}", pattern: "${context}/${group1}_vs_${group2}/input.bed", mode: 'copy', enabled: true

    input:
    tuple val(context), val(samples), path(bedGraph), val(group1), val(group2)
    // eg. [CpG, [group1, group2], [/path/to/group1_rep1.bed,/path/to/group2_rep1.bed], group1, group2]

    output:
    tuple val(context), path(context), val(group1), val(group2)
    // eg. [CpG, /path/to/CpG, group1, group2]
    path "${context}/${group1}_vs_${group2}/input.bed"

    script:
    """
    mkdir tmp ${context} ${context}/${group1}_vs_${group2}

    # build the header
    echo chr pos \$(echo ${group1}*.bed | sed -r 's/.bed([[:space:]]|\$)/\\1/g') \$(echo ${group2}*.bed | sed -r 's/.bed([[:space:]]|\$)/\\1/g') |
    tr " " "\\t" > ${context}/${group1}_vs_${group2}/input.bed 

    # run bedtools unionbedg and sort output
    bedtools unionbedg -filler . -i ${group1}*.bed ${group2}*.bed |
    cut -f1,3- | awk '{printf "%s\\t%s", \$1,\$2; for(i=3;i<=NF;i++){if(\$i=="."){printf "\\t%s",\$i} else {printf "\\t%1.2f",\$i}}; print null}' |
    sort -k1,1 -k2,2n -T tmp >> ${context}/${group1}_vs_${group2}/input.bed
    """

}


// running metilene for DMR or DMP calling
process "metilene" {

    label "mid"
    tag "${context} - ${group1}_vs_${group2}"

    maxForks "${params.fork}".toInteger()

    publishDir "${params.output}", pattern: "${context}/${group1}_vs_${group2}/*.{bed,log}", mode: 'copy', enabled: true
    publishDir "${params.output}", pattern: "${context}/*.bed", mode: 'copyNoFollow', enabled: true

    input:
    tuple val(context), path("inputs"), val(group1), val(group2)
    // eg. [CpG, /path/to/inputs, group1, group2]

    output:
    tuple val(context), path("inputs"), path(context), val(group1), val(group2)
    // eg. [CpG, /path/to/inputs, /path/to/CpG, group1, group2]
    path "${context}/${group1}_vs_${group2}/*.{bed,log}"
    path "${context}/*.bed"

    script:
    segContext = "${params.segContext}".split(",")
    """
    mkdir tmp ${context} ${context}/${group1}_vs_${group2}
    bed=inputs/${group1}_vs_${group2}/input.bed

    # define resample rate parameters
    X=\$(printf "%.0f\\n" \$(echo \$(head -1 \$bed | grep -o ${group1} | wc -l)*${params.resample} | bc -l))
    Y=\$(printf "%.0f\\n" \$(echo \$(head -1 \$bed | grep -o ${group2} | wc -l)*${params.resample} | bc -l))

    # run metilene
    metilene ${params.dmp ? "-f 3 " : segContext.contains(context) ? "-G ${params.segSize} " : ""}-X \$X -Y \$Y -a ${group1} -b ${group2} \\
    -M ${params.gap} ${params.bonferroni ? "" : "-c 2 "}-m ${params.CpN} -d ${params.diff.toInteger()/100} -t ${task.cpus} \\
    \$bed 1> ${context}/${group1}_vs_${group2}/${group1}_vs_${group2}.bed 2> ${context}/${group1}_vs_${group2}/${group1}_vs_${group2}.log || exit \$?

    # filter metilene output
    awk 'BEGIN {OFS="\\t"} \$4 <= ${params.sig} {len=\$3-\$2; print \$1,\$2,\$3,\$6,\$5,\$4,len}' ${context}/${group1}_vs_${group2}/${group1}_vs_${group2}.bed |
    sort -k1,1 -k2,2n -T tmp > ${context}/${group1}_vs_${group2}/${group1}_vs_${group2}.${params.sig}.bed
    ln -s ${group1}_vs_${group2}/${group1}_vs_${group2}.${params.sig}.bed ${context}/${group1}_vs_${group2}.bed
    """

}


// VISUALISATION PROCESS
process "distributions" {

    label "mid"
    tag "${context} - ${group1}_vs_${group2}"

    maxForks "${params.fork}".toInteger()

    publishDir "${params.output}", pattern: "${context}/${group1}_vs_${group2}/*.{txt,pdf}", mode: 'move', enabled: true

    input:
    tuple val(context), path("ignores"), path("inputs"), val(group1), val(group2)
    // eg. [CpG, /path/to/ignores, /path/to/inputs, group1, group2]
    // bedfile = [chr, start, end, #CpN, meth_diff, q-value, length]

    output:
    path "${context}/${group1}_vs_${group2}/*.{txt,pdf}"

    script:
    """
    mkdir ${context} ${context}/${group1}_vs_${group2}
    bed=inputs/${group1}_vs_${group2}/${group1}_vs_${group2}.${params.sig}.bed
    
    # check that regions exist
    if [ \$(cat \$bed | wc -l) -ne "0" ]; then
    awk 'BEGIN{OFS="\\t"} {if(\$5>0) {print "hypermethylated",\$4,\$5,\$7} else {print "hypomethylated",\$4,\$5,\$7}}' \$bed \\
    > ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).txt;
    else
    echo "hypermethylated 0 0 0" | tr " " "\\t" > ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).txt;
    echo "hypomethylated 0 0 0" | tr " " "\\t" >> ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).txt;
    fi

    # run R script 
    Rscript ${baseDir}/bin/distributions.R ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).txt
    """

}


// HEATMAP PROCESS
process "heatmaps" {

    label "mid"
    tag "${context} - ${group1}_vs_${group2}"

    maxForks "${params.fork}".toInteger()

    publishDir "${params.output}", pattern: "${context}/${group1}_vs_${group2}/*.{avg,pdf}", mode: 'copy', enabled: true

    input:
    tuple val(context), path("positions"), path("regions"), val(group1), val(group2)
    // eg. [CpG, /path/to/positions, /path/to/regions, group1, group2]
    // positions = /path/to/input/group1_vs_group2.bed from bedtools_unionbedg
    // regions = /path/to/metilene/group1_vs_group2.0.05.bed from metilene

    output:
    path "${context}/${group1}_vs_${group2}/*.{avg,pdf}"

    script:
    """
    mkdir ${context} ${context}/${group1}_vs_${group2}
    pos=positions/${group1}_vs_${group2}/input.bed
    bed=regions/${group1}_vs_${group2}/${group1}_vs_${group2}.${params.sig}.bed
    
    # calculate sample averages and run R script
    ${baseDir}/bin/average_over_bed.py \$bed \$pos > ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).avg
    Rscript ${baseDir}/bin/heatmap.R ${context}/${group1}_vs_${group2}/\$(basename \$bed .bed).avg
    """

}
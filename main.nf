#!/usr/bin/env nextflow

// DSL2 BRANCH
nextflow.preview.dsl=2

// PRINT HELP AND EXIT
if(params.help){
    println """\

         ===============================================
          E P I D I V E R S E - D M R   P I P E L I N E
         ===============================================
         ~ version ${workflow.manifest.version}

         Usage: 
              nextflow run epidiverse/dmr [OPTIONS]...

         Options: GENERAL
              --input [path/to/input/dir]     [REQUIRED] Specify the path to the directory containing each sample output
                                          from the wgbs pipeline to be taken forward for analysis. All the subdirectories must
                                          correspond to sample names in the provided samples file, and contain within them a
                                          bedGraph directories with files in '*.bedGraph' format.

              --samples [path/to/samples.tsv] [REQUIRED] Specify the path to the "samples.tsv" file containing information 
                                          regarding sample names and corresponding groupings/replicates. The file must contain
                                          three tab-separated columns: 1) sample names, corresponding to subdirectories in the
                                          --input directory. 2) group names, for grouping samples together. 3) replicate names
                                          to provide easy-to-read alternatives for complicated sample names.

              --output [path/to/output/dir]   A path to a location to write the output results directory, which can be relative
                                          or absolute. This directory will contain sub-directories for each group comparison
                                          analysed during the pipeline. [default: dmrs]


         Options: MODIFIERS
              --control [STR]                 Specify a string that corresponds to a group name in the provided "samples.tsv",
                                          and the pipeline will run DMR comparisons for each group relative to this group.
                                          Otherwise, the pipeline will run all possible pairwise comparisons if no control
                                          group is specified. [default: off]

              --dmp                           Specify that DMPs should be analysed instead of DMRs. [default: off]

              --noCpG                         Disables DMR analysis in CpG context. [default: off] 
              --noCHG                         Disables DMR analysis in CHG context. [default: off]
              --noCHH                         Disables DMR analysis in CHH context. [default: off]


         Options: DMR FILTERING
              --cov [INT]                     Specify the minimum coverage threshold to filter methylated positions before running
                                          the DMR analyses. [default: 5]

              --sig [FLOAT]                   Specify the maximum q-value threshold for filtering DMRs post-analysis. [default: 0.05]

              --diff [INT]                    Specify the minimum differential methylation level (percent) for filtering DMRs
                                          post-analysis. [default: 10]

              --CpN [INT]                     Minimum number of Cs a DMR needs to contain in order to be reported. [default: 10]
              
              --gap [INT]                     Minimum distance (bp) between Cs that are not to be considered as part of the same
                                          DMR. [default: 146]
              
              --resample [FLOAT]              Minimum proportion of group samples that must be present in a given position in order
                                          to resample missing data [default: 0.8]

              --bonferroni                    Specify Bonferroni method for multiple comparison testing, otherwise Benjamini-Hochberg
                                          will be used by default. [default: off]

              --segSize [INT]                 Give a hard cutoff for presegmenting regions prior to DMR identification. Higher
                                          values improve runtimes in CHG and CHH context but limit the capacity to identify DMRs
                                          that overlap the cutoff location. Can be turned off with 0. [default: 1000]

              --segContext [STR]              Give a comma-delimited string of methylation contexts where you wish to apply the 
                                          heuristic --segSize parameter. [default: CHH]

         Options: ADDITIONAL
              --help                          Display this help information and exit
              --version                       Display the current pipeline version and exit
              --debug                         Run the pipeline in debug mode    


         Example: 
              nextflow run epidiverse/dmr \
              --input path/to/wgbs/dir \
              --samples path/to/samples.tsv \
              --output dmrs

    """
    ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute()
    exit 0
}

// PRINT VERSION AND EXIT
if(params.version){
    println """\
         ===============================================
          E P I D I V E R S E - D M R   P I P E L I N E
         ===============================================
         ~ version ${workflow.manifest.version}
    """
    ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute()
    exit 0
}

// PARAMETER CHECKS
if( params.noCpG && params.noCHG && params.noCHH ){error "ERROR: please specify at least one methylation context for analysis"}

// DEFINE COMMALINE FOR INPUT PATH
def commaLine = ""
file("${params.samples}")
    .readLines()
    .each { def line = it.toString().tokenize('\t').get(0)
         commaLine += line
         commaLine += "," }

// DEFINE PATHS
CpG_path = "${params.input}/{${commaLine[0..-2]}}/bedGraph/*_CpG.bedGraph"
CHG_path = "${params.input}/{${commaLine[0..-2]}}/bedGraph/*_CHG.bedGraph"
CHH_path = "${params.input}/{${commaLine[0..-2]}}/bedGraph/*_CHH.bedGraph"


// PRINT STANDARD LOGGING INFO
log.info ""
log.info "         ================================================"
log.info "          E P I D I V E R S E - D M R    P I P E L I N E"
if(params.debug){
log.info "         (debug mode enabled)"
log.info "         ================================================" }
else {
log.info "         ================================================" }
log.info "         ~ version ${workflow.manifest.version}"
log.info ""
log.info "         input dir     : ${params.input}"
log.info "         samples file  : ${params.samples}"
log.info "         pairwise      : ${params.control ? "${params.control}" : "all"} vs all"
log.info "         context(s)    : ${params.noCpG ? "" : "CpG "}${params.noCHH ? "" : "CHH "}${params.noCHG ? "" : "CHG"}"
log.info "         analysis      : ${params.dmp ? "DMPs" : "DMRs"}"
log.info "         output dir    : ${params.output}"
log.info ""
log.info "         DMR-Filtering"
log.info "         ================================================"
log.info "         hard segments : ${params.segSize} bp ${params.segContext ? "(${params.segContext})" : ""}"
log.info "         resample rate : ${params.resample}"
log.info "         CpN coverage  : ${params.cov}"
log.info "         CpN distance  : ${params.gap} bp"
log.info "         min. CpN      : ${params.CpN}"
log.info "         min. diff     : ${params.diff}%"
log.info "         significance  : ${params.sig}"
log.info "         test          : ${params.bonferroni ? "Bonferroni" : "Benjamini-Hochberg FDR"}"
log.info ""
log.info "         ================================================"
log.info "         RUN NAME: ${workflow.runName}"
log.info ""



/////////////////////
// COMMON CHANNELS //
/////////////////////

// STAGE SAMPLES CHANNEL
samples_channel = Channel
    .from(file("${params.samples}").readLines())
    .ifEmpty{ exit 1, "ERROR: samples file is missing or invalid. Please remember to use the --samples parameter." }
    .map { line ->
        def field = line.toString().tokenize('\t').take(3)
        return tuple(field[0].replaceAll("\\s",""), field[1].replaceAll("\\s",""), field[2].replaceAll("\\s",""))}

// handle errors with params.control
samples_channel
    .count{it[1] == params.control}
    .subscribe{int c ->
        if( params.control && c == 0 ){
            error "ERROR: --control parameter does not match with samples in: ${params.samples}"
            exit 1
        }
    }

// STAGE COMBINATIONS
combinations = samples_channel
    .map{it[1]}
    .collect()
    .map{[params.control ? tuple(params.control.toString()) : it,it].combinations().findAll{a,b -> a < b}}
    .flatMap()
    .unique()

// STAGE BEDGRAPH CHANNELS FROM TEST PROFILE
if ( workflow.profile.tokenize(",").contains("test") ){

        include check_test_data from './libs/functions.nf' params(CpGPaths: params.CpGPaths, CHGPaths: params.CHGPaths, noCpG: params.noCpG, noCHG: params.noCHG)
        (CpG, CHG, CHH) = check_test_data(params.CpGPaths, params.CHGPaths, params.noCpG, params.noCHG)

} else {

    // STAGE BEDGRAPH CHANNELS
    CpG = params.noCpG ? Channel.empty() : Channel
        .fromFilePairs(CpG_path, size: 1)
        .ifEmpty{ exit 1, "ERROR: cannot find valid *_CpG.bedGraph files in dir: ${params.input}\n"}
        .map{it.flatten()}

    CHG = params.noCHG ? Channel.empty() : Channel
        .fromFilePairs(CHG_path, size: 1)
        .ifEmpty{ exit 1, "ERROR: cannot find valid *_CHG.bedGraph files in dir: ${params.input}\n"}
        .map{it.flatten()}

    CHH = params.noCHH ? Channel.empty() : Channel
        .fromFilePairs(CHH_path, size: 1)
        .ifEmpty{ exit 1, "ERROR: cannot find valid *_CHH.bedGraph files in dir: ${params.input}\n"}
        .map{it.flatten()}
}

// ASSIGN GROUP AND REP NAMES TO CHANNELS
CpG_channel = CpG.combine(samples_channel, by: 0).map{tuple("CpG", *it)}
CHG_channel = CHG.combine(samples_channel, by: 0).map{tuple("CHG", *it)}
CHH_channel = CHH.combine(samples_channel, by: 0).map{tuple("CHH", *it)}

// STAGE FINAL INPUT CHANNEL
input_channel = CpG_channel.mix(CHG_channel,CHH_channel)


////////////////////
// BEGIN PIPELINE //
////////////////////

// INCLUDES
include './libs/dmr.nf' params(params)

// WORKFLOWS

// WGBS workflow - primary pipeline
workflow 'DMRS' {

    get:
        input_channel
        samples_channel
        combinations
 
    main:
        preprocessing(input_channel)
        bedtools_unionbedg(preprocessing.out.groupTuple().combine(combinations))
        metilene(bedtools_unionbedg.out[0])
        distributions(metilene.out[0])
        heatmaps(metilene.out[0])

    emit:
        bedtools_unionbedg_publish = bedtools_unionbedg.out[1]
        metilene_publish = metilene.out[1]
        distributions_publish = distributions.out
        heatmaps_publish = heatmaps.out

}


// MAIN workflow
workflow {

    main:
        DMRS(input_channel,samples_channel,combinations)

    publish:
        DMRS.out.bedtools_unionbedg_publish to: "${params.output}", mode: 'copy'
        DMRS.out.metilene_publish to: "${params.output}", mode: 'copy'
        DMRS.out.distributions_publish to: "${params.output}", mode: 'move'
        DMRS.out.heatmaps_publish to: "${params.output}", mode: 'copy'

}


//////////////////
// END PIPELINE //
//////////////////



// WORKFLOW TRACING
workflow.onError {
    log.info "Oops... Pipeline execution stopped with the following message: ${workflow.errorMessage}"
}

workflow.onComplete {

    log.info ""
    log.info "         Pipeline execution summary"
    log.info "         ---------------------------"
    log.info "         Name         : ${workflow.runName}${workflow.resume ? " (resumed)" : ""}"
    log.info "         Profile      : ${workflow.profile}"
    log.info "         Launch dir   : ${workflow.launchDir}"    
    log.info "         Work dir     : ${workflow.workDir} ${params.debug ? "" : "(cleared)" }"
    log.info "         Status       : ${workflow.success ? "success" : "failed"}"
    log.info "         Error report : ${workflow.errorReport ?: "-"}"
    log.info ""

    if (params.debug == false && workflow.success) {
        ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute() }
}
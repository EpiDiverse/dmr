#!/usr/bin/env nextflow

// FUNCTION TO LOAD DATASETS IN TEST PROFILE
def check_test_data(CpGPaths,CHGPaths,noCpG,noCHG) {

    // Set CpG testdata
    CpG = noCpG ? Channel.empty() : Channel
        .from(CpGPaths)
        .map { row -> [ row[0], file(row[1]) ] }
        .ifEmpty { exit 1, "params.CpGPaths was empty - no input files supplied" }

    // Set CHG testdata
    CHG = noCHG ? Channel.empty() : Channel
        .from(CHGPaths)
        .map { row -> [ row[0], file(row[1]) ] }
        .ifEmpty { exit 1, "params.CHGPaths was empty - no input files supplied" }

    // Return CpG, CHG, CHH channels respectively
    return tuple(CpG, CHG, Channel.empty())
}
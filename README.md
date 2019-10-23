[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.09.0-brightgreen.svg)](https://www.nextflow.io/)
[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/epidiverse/dmr.svg)](https://hub.docker.com/r/epidiverse/dmr)

EpiDiverse-DMR Pipeline
========================

**EpiDiverse/dmr** is a bioinformatics analysis pipeline for calling differentially methylated positions or regions from non-model plant species.

The workflow processes raw methylation data from bedGraphs resulting from the [EpiDiverse/wgbs](https://github.com/epidiverse/wgbs/) pipeline, which are then grouped for analysis with [bedtools unionbedg](https://github.com/arq5x/bedtools2). Each pairwise comparison between groups is performed with [metilene](https://www.bioinf.uni-leipzig.de/Software/metilene/), and downstream visualisation is carried out with R-packages [ggplot2]() and [gplots]() to produce distribution plots and heatmaps.

See the [output documentation](https://github.com/EpiDiverse/dmr/wiki/Pipeline-Output) for more details of the results.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

i. Install [`nextflow`](https://www.nextflow.io/)

ii. Install one of [`docker`](https://docs.docker.com/engine/installation/), [`singularity`](https://www.sylabs.io/guides/3.0/user-guide/) or [`conda`](https://conda.io/miniconda.html)

iii. Download the pipeline and test it on a minimal dataset with a single command

```bash
nextflow run epidiverse/dmr -profile test,<docker|singularity|conda>
```

iv. Start running your own analysis!

```bash
nextflow run epidiverse/dmr -profile <docker|singularity|conda> --input /path/to/wgbs/dir --samples /path/to/samples.tsv
```

See [usage docs](https://github.com/EpiDiverse/dmr/wiki/Pipeline-Usage) for all of the available options when running the pipeline.

### Wiki Documentation

The epidiverse/dmr pipeline comes with documentation about the pipeline, [found in the Wiki](https://github.com/EpiDiverse/dmr/wiki):

1. [Installation](https://github.com/EpiDiverse/dmr/wiki/Installation)
2. Pipeline configuration
    * [Local installation](https://github.com/EpiDiverse/dmr/wiki/Installation#2-install-the-pipeline)
    * [Adding your own system config](https://github.com/EpiDiverse/dmr/wiki/Installation#3-pipeline-configuration)
    * [EpiDiverse infrastructure](https://github.com/EpiDiverse/dmr/wiki/Installation#appendices)
3. [Running the pipeline](https://github.com/EpiDiverse/dmr/wiki/Pipeline-Usage)
4. [Output and how to interpret the results](https://github.com/EpiDiverse/dmr/wiki/Pipeline-Output)
5. [Troubleshooting](https://github.com/EpiDiverse/dmr/wiki/Troubleshooting)

### Credits

These scripts were originally written for use by the [EpiDiverse International Training Network](https://epidiverse.eu/), by Adam Nunn ([@bio15anu](https://github.com/bio15anu)) and Nilay Can ([@nilaycan](https://github.com/nilaycan)).

This project has received funding from the European Union’s Horizon 2020 research and innovation
programme under the Marie Skłodowska-Curie grant agreement No 764965

## Citation

If you use epidiverse/dmr for your analysis, please cite it using the following doi: <placeholder>
This document describes the output produced by the pipeline.

## Pipeline overview
The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

* [bedtools unionbedg](#bedtools-unionbedg) - compiling pairwise comparisons between groups
* [metilene](#metilene) - calling differentially methylated positions/regions
* [Visualisation](#visualisation) - distributions and heatmaps
* [Pipeline Info](#pipeline-info) - reports from nextflow about the pipeline run

## bedtools unionbedg

## metilene

## Visualisation

### Methylation heatmaps
![Methylation heatmaps](images/heatmap.png)

### Distributions
#### Methylation difference
![Methylation difference](images/methylation.png)
#### DMR lengths
![Length distribution](images/length.png)
#### CpN content
![CpN distribution](images/CpN.png)
#### Hyper- vs hypomethylation
![Hyper- vs hypomethylation](images/piechart.png)



## Pipeline Info
Nextflow has several built-in reporting tools that give information about the pipeline run.

**Output directory: `results/`**

* `dag.svg`
  * DAG graph giving a diagrammatic view of the pipeline run.
  * NB: If [Graphviz](http://www.graphviz.org/) was not installed when running the pipeline, this file will be in [DOT format](http://www.graphviz.org/content/dot-language) instead of SVG.
* `report.html`
  * Nextflow report describing parameters, computational resource usage and task bash commands used.
* `timeline.html`
  * A waterfall timeline plot showing the running times of the workflow tasks.
* `trace.txt`
  * A text file with machine-readable statistics about every task executed in the pipeline.
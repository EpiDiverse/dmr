# EpiDiverse-DMR Runtime and memory usage guidelines
This document describes the default CPUs, RAM, and Time allocation specified for each pipeline process in the default configuration of the pipeline. Configuration was optimised on a HPC cluster with 64 CPUs and 256 Gb RAM, using the collection of plant population datasets provided by EpiDiverse. All values can be adjusted to suit individual needs.

|process|CPUs|RAM / Gb|Time / h|Retries|[errorStrategy](https://www.nextflow.io/docs/latest/process.html#errorstrategy)|
|-------|----|--------|--------|-------|-----------------|
|preprocessing|2|2|3|3|finish|
|bedtools_unionbedg|2|2|3|3|finish|
|metilene|4|4|3|3|finish|
|distributions|2|8|3|3|ignore|
|heatmaps|2|8|3|3|ignore|
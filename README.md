# IHEC processing

## RNA-seq: grape-nf, CRG (TESTED)
https://github.com/guigolab/grape-nf

### convenience scripts

* **ihec.rna-seq-processing.sh**: wraps grape-nf together with trim\_galore trimming. In order to use:
  1. install conda environment from ihec.rna-seq.processing/grape-nf\_environment.yaml
  1. configure paths and folders in all scripts

## DNase I/ATAC: atac-seq-pipeline, Encode (TESTED)
https://github.com/ENCODE-DCC/atac-seq-pipeline

### convenience scripts

* **prepEncodePipelineConfig.py**: easy generation of configuration files. Does not support replicates yet

## ChIP-seq: chip-seq-pipeline2, Encode
https://github.com/ENCODE-DCC/chip-seq-pipeline2

## WGBS: gemBS, CRG
https://github.com/heathsc/gemBS

wrapper in development at Encode:
https://github.com/ENCODE-DCC/wgbs-pipeline


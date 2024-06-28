# SNPs and INDELs variant calling by integrating HaplotypeCaller and DeepVariant using matched WES and RNA-Seq data
This repository contains codes used and supplementary files for the research article: Computational Integration of HaplotypeCaller and DeepVariant Reveals Novel Consensus Germline Variants across Matched WES and RNA-Seq Pulmonary Carcinoid Samples

## Directories
# 1: Scripts
**auto_script.sh**  
A bash script that autmoate the analysis pipeline starting from raw data in FASTQ format to reporting variants in VCF format.  
Command: ```bash auto_script.sh input.txt```  
**input.txt**  
A tab-delimited txt file that the user can download and edit based on their input file names and reference. It has the following columns in order:  
R1_fileName  R2_fileName  /directoryToReference/reference.fasta  indexedReference  prefixOfOutputFiles  VariantCaller(HC or DV)  DataType(DNA or RNA) 



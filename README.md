# SNPs and INDELs variant calling by integrating HaplotypeCaller and DeepVariant using matched WES and RNA-Seq data
This repository contains codes used and supplementary files for the research article: Computational Integration of HaplotypeCaller and DeepVariant Reveals Novel Consensus Germline Variants across Matched WES and RNA-Seq Pulmonary Carcinoid Samples

## Directories
### Scripts
**auto_script.sh**  
A bash script that autmoate the analysis pipeline starting from raw data in FASTQ format to reporting variants in VCF format. It is preferred that the script file, input.txt file, and FASTQ files to be located in the same directory.
Command: ```bash auto_script.sh input.txt```  
**input.txt**  
A tab-delimited txt file that the user can download and edit based on their input file names and reference. It has the following columns in order:  
R1_fileName  
R2_fileName  
/directoryToReference/reference.fasta  
indexedReference  
prefixOfOutputFiles  
VariantCaller (HC or DV)  
DataType (DNA or RNA) 

**coverage_script.txt**  
Script used to calculate coverage for each sample data type

**VCF_intersection_script.sh and venn.py**  
Scripts used to conclude intersecting variants across variant callers, data types, and both. ```venn.py``` was used to visualize these intersections in Venn diagrams.

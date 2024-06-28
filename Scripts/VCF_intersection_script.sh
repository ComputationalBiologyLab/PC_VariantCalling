#Nehal: we need to create intersections between VCF files for SNPs and INDELs separately, check if we can normaliza VCF files so we do not miss INDELs as intersecting between variant callers
#Rofida: Done we do this and put the output files in the drive
#Nehal: another tool has been recommended to test in the manuscript and compare
#Rofida: we use bcftool once and vcf-compare once
#Nehal: I need you to draw Venn diagrams from these output files
#Rofida: Done, we redirect in a bash script to run Venn.py to draw 
#!/bin/bash

# Define arrays to store the file paths
#Nehal: can we make the code more generic accepting file name output of the auto_script?
#Rofida: We can put to enter string of files as array , is this you want ? but we want this in correct format as array like the example in below
#Deep Variant files
dna_files=("DV/CT-6/out400_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-10/out404_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-15/out410_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-20/out414_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-21/out416_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-26/out420_filtered_DP_QUAL_GQ.vcf.gz")
rna_files=("DV/CT-6/out26_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-10/out27_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-15/out30_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-20/out28_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-21/out29_filtered_DP_QUAL_GQ.vcf.gz" "DV/CT-26/out31_filtered_DP_QUAL_GQ.vcf.gz")

#Haplotype files
dna_files2=("HC/400_haplo.filtered.vcf.gz" "HC/404_haplo.filtered.vcf.gz" "HC/410_haplo.filtered.vcf.gz" "HC/414_haplo.filtered.vcf.gz" "HC/416_haplo.filtered.vcf.gz" "HC/420_haplo.filtered.vcf.gz")
rna_files2=("HC/26_haplo.filtered.vcf.gz" "HC/27_haplo.filtered.vcf.gz"  "HC/28_haplo.filtered.vcf.gz" "HC/29_haplo.filtered.vcf.gz" "HC/30_haplo.filtered.vcf.gz" "HC/31_haplo.filtered.vcf.gz")


 
# Define a function to get the intersection of two files
#Nehal: I think here we should order the commands so that the function index the input first; then execute intersection, then index output
#Rofida: Done
get_intersection () {
    input_file_1=$1
    input_file_2=$2
    output_dir=$3
    output_prefix=$4
    
    # Index input files
    #Nehal: I think we miss -t parameter to get tbi indexed format #Nehal: The command index RNA files only and not DNA files, hence no DNA analysis done
    #Rofida: Done
    bcftools index -t "$input_file_1"
    bcftools index -t "$input_file_2"

    # Compute intersection
    bcftools isec "$input_file_1" "$input_file_2" -p "$output_dir" -Oz -o "$output_dir/$output_prefix.vcf.gz"
    
    #Nehal: -p parameter above should automatically create indexed files, we won't need the below code #Done
}

##############################################
#DeepVariant
##############################################
# Get intersection of the first two DNA files
get_intersection "${dna_files[0]}" "${dna_files[1]}" "output1_dna_DV" "0002"
output_file_dna_DV=output1_dna_DV/0002.vcf.gz

# Get intersection of the remaining DNA files
#Nehal: we better rename the last output filder but if not feasible we can state as a comment here that VCF containing intersection of samples is in folder output5 and it is 002
#Rofida: Done , I edit it in below
for ((i=2; i<${#dna_files[@]}; i++))
do
    echo $output_file_dna 
    echo ${dna_files[$i]}
    echo "**********************************" 
    get_intersection "$output_file_dna_DV" "${dna_files[$i]}" "output$((i))_dna_DV" "0002"
     output_file_dna_DV=output$((i))_dna_DV/0002.vcf.gz
done

#Rename the folder and the file
mv output5_dna_DV "Intersection_of_WES_files_of_DV"
mv Intersection_of_WES_files_of_DV/0002.vcf.gz  Intersection_of_WES_files_of_DV/Intersection_WES_DV.vcf.gz


# Get intersection of the first two RNA files
get_intersection "${rna_files[0]}" "${rna_files[1]}" "output1_rna_DV" "0002"
output_file_rna_DV=output1_rna_DV/0002.vcf.gz

# Get intersection of the remaining RNA files
for ((i=2; i<${#rna_files[@]}; i++))
do
    echo $output_file_rna 
    echo ${rna_files[$i]}
    echo "**********************************"
    get_intersection "$output_file_rna_DV" "${rna_files[$i]}" "output$((i))_rna_DV" "0002"
    output_file_rna_DV=output$((i))_rna_DV/0002.vcf.gz
done


#Rename the folder and the file
mv output5_rna_DV "Intersection_of_RNASeq_files_of_DV"
mv Intersection_of_RNASeq_files_of_DV/0002.vcf.gz Intersection_of_RNASeq_files_of_DV/Intersection_RNASeq_DV.vcf.gz



# Get intersection of DNA and RNA files
#Nehal: do we miss intersection between variant callers and data types?
#Nehal: Please add the type of variant caller then the missing command between two variant callers
#Nehal: can we refer to the 002 file as it is the resulting output in the final output folder?
#Rofida: all of these done in below
bcftools index -t Intersection_of_RNASeq_files_of_DV/Intersection_RNASeq_DV.vcf.gz 
bcftools index -t Intersection_of_WES_files_of_DV/Intersection_WES_DV.vcf.gz
bcftools isec Intersection_of_RNASeq_files_of_DV/Intersection_RNASeq_DV.vcf.gz Intersection_of_WES_files_of_DV/Intersection_WES_DV.vcf.gz -p DV_intersect_RNAseq_and_WES -Oz -o "0002"
mv DV_intersect_RNAseq_and_WES/0002.vcf.gz DV_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_DV.vcf.gz
mv DV_intersect_RNAseq_and_WES/0000.vcf.gz DV_intersect_RNAseq_and_WES/Uniq_of_RNAseq_DV.vcf.gz
mv DV_intersect_RNAseq_and_WES/0001.vcf.gz DV_intersect_RNAseq_and_WES/Uniq_of_WES_DV.vcf.gz
bcftools index -t DV_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_DV.vcf.gz
bcftools index -t DV_intersect_RNAseq_and_WES/Uniq_of_RNAseq_DV.vcf.gz
bcftools index -t DV_intersect_RNAseq_and_WES/Uniq_of_WES_DV.vcf.gz
##############################################
#Haplotype
##############################################
# Get intersection of the first two DNA files
get_intersection "${dna_files2[0]}" "${dna_files2[1]}" "output1_dna_HC" "0002"
output_file_dna_HC=output1_dna_HC/0002.vcf.gz

# Get intersection of the remaining DNA files

for ((i=2; i<${#dna_files2[@]}; i++))
do
    echo $output_file_dna 
    echo ${dna_files2[$i]}
    echo "**********************************" 
    get_intersection "$output_file_dna_HC" "${dna_files2[$i]}" "output$((i))_dna_HC" "0002"
     output_file_dna_HC=output$((i))_dna_HC/0002.vcf.gz
done

#Rename the folder and the file
mv output5_dna_HC "Intersection_of_WES_files_of_HC"
mv Intersection_of_WES_files_of_HC/0002.vcf.gz  Intersection_of_WES_files_of_HC/Intersection_WES_HC.vcf.gz


# Get intersection of the first two RNA files
get_intersection "${rna_files2[0]}" "${rna_files2[1]}" "output1_rna_HC" "0002"
output_file_rna_HC=output1_rna_HC/0002.vcf.gz

# Get intersection of the remaining RNA files
for ((i=2; i<${#rna_files2[@]}; i++))
do
    echo $output_file_rna 
    echo ${rna_files2[$i]}
    echo "**********************************"
    get_intersection "$output_file_rna_HC" "${rna_files2[$i]}" "output$((i))_rna_HC" "0002"
    output_file_rna_HC=output$((i))_rna_HC/0002.vcf.gz
done


#Rename the folder and the file
mv output5_rna_HC "Intersection_of_RNASeq_files_of_HC"
mv Intersection_of_RNASeq_files_of_HC/0002.vcf.gz Intersection_of_RNASeq_files_of_HC/Intersection_RNASeq_HC.vcf.gz



# Get intersection of DNA and RNA files

bcftools index -t Intersection_of_RNASeq_files_of_HC/Intersection_RNASeq_HC.vcf.gz 
bcftools index -t Intersection_of_WES_files_of_HC/Intersection_WES_HC.vcf.gz
bcftools isec Intersection_of_RNASeq_files_of_HC/Intersection_RNASeq_HC.vcf.gz Intersection_of_WES_files_of_HC/Intersection_WES_HC.vcf.gz -p HC_intersect_RNAseq_and_WES -Oz -o "0002"
mv HC_intersect_RNAseq_and_WES/0002.vcf.gz HC_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_HC.vcf.gz
mv HC_intersect_RNAseq_and_WES/0000.vcf.gz HC_intersect_RNAseq_and_WES/Uniq_of_RNAseq_HC.vcf.gz
mv HC_intersect_RNAseq_and_WES/0001.vcf.gz HC_intersect_RNAseq_and_WES/Uniq_of_WES_HC.vcf.gz
bcftools index -t HC_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_HC.vcf.gz
bcftools index -t HC_intersect_RNAseq_and_WES/Uniq_of_RNAseq_HC.vcf.gz
bcftools index -t HC_intersect_RNAseq_and_WES/Uniq_of_WES_HC.vcf.gz

#######################################
#Intersection of Intersections
#######################################

bcftools isec HC_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_HC.vcf.gz DV_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_DV.vcf.gz -p HC_DV_intersect_RNAseq_and_WES -Oz -o "0002"
mv HC_DV_intersect_RNAseq_and_WES/0002.vcf.gz HC_DV_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz
mv HC_DV_intersect_RNAseq_and_WES/0000.vcf.gz HC_DV_intersect_RNAseq_and_WES/Uniq_for_HC_of_Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz
mv HC_DV_intersect_RNAseq_and_WES/0001.vcf.gz HC_DV_intersect_RNAseq_and_WES/Uniq_for_DV_of_Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz
bcftools index -t HC_DV_intersect_RNAseq_and_WES/Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz
bcftools index -t HC_DV_intersect_RNAseq_and_WES/Uniq_for_HC_of_Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz
bcftools index -t HC_DV_intersect_RNAseq_and_WES/Uniq_for_DV_of_Intersection_of_RNAseq_and_WES_HC_DV.vcf.gz

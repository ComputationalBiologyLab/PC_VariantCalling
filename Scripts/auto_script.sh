#! /usr/bin/bash
#Check if packages found or not if not install it 
# To run the following script --> bash auto_script.sh input.txt
Packages=("bwa" "fastp" "samtools" "openjdk-8-jdk" "hisat2" "bcftools")
for pkg in "${Packages[@]}"; do
	if dpkg -s $pkg &> /dev/null
	then
		echo "$pkg is installed."
	else
		echo "$pkg is not installed. Installing $pkg..."
		sudo apt -y install $pkg &> /dev/null
		echo "$pkg has been successfully installed."
	fi
done

if command -v picard >/dev/null 2>&1 ; then
  echo "Picard Tools is already installed."
  jar="/usr/local/bin/picard.jar"
else
  echo "Picard Tools is not installed. Installing now..."
  wget https://github.com/broadinstitute/picard/releases/download/2.23.3/picard.jar
  sudo mv picard.jar /usr/local/bin/picard.jar
  sudo ln -s /usr/local/bin/picard.jar /usr/local/bin/picard
  jar="/usr/local/bin/picard.jar"
  echo "Picard Tools has been successfully installed."
fi

Pre_Processing(){
To_Fastp
To_Align
To_Add_Read_Groups
To_Sort
To_Mark_Duplicates
To_Index
}

Call_Variant(){
if [ "$VariantCallerName" == "HC" ]; then 
	echo "We will run HaplotypeCaller..."
	HaplotypeCaller
else
	echo "We will run DeepVariant..."
	if [ "$datatype" == "DNA" ]; then
		echo "Running DNA DeepVariant..." 
		Call_DeepVariant_DNA
	else
		echo "Running RNA DeepVariant..."
		Call_DeepVariant_RNA
	fi
fi
}
To_Fastp(){
echo "Fastp the following files: "$forward, $reverse
fastp -i $forward -I $reverse -o $cwd/Fastp_files/$ID"_R1.fil.fastq.gz" -O $cwd/Fastp_files/$ID"_R2.fil.fastq.gz"  --json $cwd/Fastp_files/$ID.json  --html $cwd/Fastp_files/$ID.html
echo "Reads are filtered successfully!" 
}

To_Align(){
if [ "$datatype" == "DNA" ];
then
	#echo "Indexing the reference..."
	#bwa index -p $Ref/$index $Reference_File
	if [ -f "$Ref/$index.pac" ] && [ -f "$Ref/$index.ann" ] && [ -f "$Ref/$index.bwt" ] && [ -f "$Ref/$index.sa" ];
	then
		echo "Reference Indexed."
	else
		echo "Indexing the reference."
		bwa index -p $Ref/$index $Reference_File
	fi
	echo "Aligning the following files: "$ID"_R1.fil.fastq.gz", $ID"_R2.fil.fastq.gz"
	time bwa mem -M  $Ref/$index $cwd/Fastp_files/$ID"_R1.fil.fastq.gz" $cwd/Fastp_files/$ID"_R2.fil.fastq.gz" > $cwd/Aligned_files/$ID.sam  
else 
	#echo "Indexing the reference..."
	#hisat2-build $Reference_File $Ref/genome
	if [ -f "$Ref/genome.6.ht2" ] || [ -f "$Ref/$index.ht2" ];
	then
		echo "Reference Indexed."
	else
		echo "Indexing the reference."
		hisat2-build $Reference_File $Ref/genome
	fi
	echo "Aligning the following files: "$ID"_R1.fil.fastq.gz", $ID"_R2.fil.fastq.gz"
	hisat2 -x $Ref/genome -1 $cwd/Fastp_files/$ID"_R1.fil.fastq.gz" -2 $cwd/Fastp_files/$ID"_R2.fil.fastq.gz" -S $cwd/Aligned_files/$ID.sam  
fi
echo "Converting sam to bam..."
java -Xmx8g -jar $jar SamFormatConverter -I $cwd/Aligned_files/$ID.sam -O $cwd/Aligned_files/$ID.bam
}

To_Add_Read_Groups(){
java -jar $jar AddOrReplaceReadGroups \
	I=$cwd/Aligned_files/$ID.bam \
	O=$cwd/Processing_files/$ID.RGG.bam \
	RGPL=illumina \
	RGID="ID_"$ID \
	RGLB=lib1 \
	RGPU=unit1 \
	RGSM=$ID
}

To_Sort(){
echo "Sorting the bam file:" $cwd/Aligned_files/$ID.bam
java -Xmx8g -jar $jar SortSam \
	I=$cwd/Processing_files/$ID.RGG.bam \
	O=$cwd/Processing_files/$ID.RGG.sorted.bam \
	SORT_ORDER=coordinate
}

To_Mark_Duplicates(){
echo "Marking Duplicates..."
java -Xmx8g -jar $jar MarkDuplicates \
	I=$cwd/Processing_files/$ID.RGG.sorted.bam \
	O=$Ref/$ID.RGG.sorted.marked.bam \
	M=$Ref/$ID"_marked_dup_metrics.txt" 
}

To_Index(){
echo "Indexing the processed files..."
samtools index  $Ref/$ID".RGG.sorted.marked.bam"
}

HaplotypeCaller(){
if command -v gatk >/dev/null 2>&1 ; then
  echo "GATK4 is already installed."
else
  echo "GATK4 is not installed. Installing now..."
  wget https://github.com/broadinstitute/gatk/releases/download/4.1.8.1/gatk-4.1.8.1.zip
  unzip gatk-4.1.8.1.zip
  rm gatk-4.1.8.1.zip
  sudo mv gatk-4.1.8.1 /usr/local/bin/gatk4
  sudo ln -s /usr/local/bin/gatk4/gatk /usr/local/bin/gatk
  echo "GATK4 has been successfully installed!"
fi
if ! dpkg -s python3 > /dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install python3
fi
whereis python3
if [ ! -e "/usr/bin/python" ]; then
    sudo ln -s /usr/bin/python3 /usr/bin/python
fi
if [ "$datatype" == "DNA" ]; then
		echo "Running DNA HaplotypeCaller..."
		HaplotypeCaller_Tumor_DNA
	else
		echo "Running RNA HaplotypeCaller..." 
		HaplotypeCaller_Tumor_RNA
	fi
}

HaplotypeCaller_Tumor_DNA(){
gatk --java-options '-Xmx16G' HaplotypeCaller \
-R $Reference_File \
-I $Ref/$ID.RGG.sorted.marked.bam \
-O $cwd/Call_Variant_Files/"HAPLO$ID.vcf"
gzip -c $cwd/Call_Variant_Files/"HAPLO$ID.vcf" > $cwd/Call_Variant_Files/"HAPLO$ID.vcf.gz"
}

HaplotypeCaller_Tumor_RNA(){
gatk --java-options '-Xmx16G' HaplotypeCaller \
-R $Reference_File \
-I $Ref/$ID.RGG.sorted.marked.bam \
-O $cwd/Call_Variant_Files/"HAPLO$ID.vcf"
gzip -c $cwd/Call_Variant_Files/"HAPLO$ID.vcf" > $cwd/Call_Variant_Files/"HAPLO$ID.vcf.gz"
}

Call_DeepVariant_DNA(){
Packages=( apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker-ce )
sudo apt-get -qq -y update
for pkg in "${Packages[@]}"; do
	if dpkg -s $pkg &> /dev/null
	then
		echo "$pkg is installed."
	else
		echo "$pkg is not installed. Installing $pkg..."
		sudo apt-get -qq -y install $pkg &> /dev/null
		echo "$pkg has been successfully installed."
	fi
done
echo "Adding Docker repository..."
sudo apt-get update 
echo "update finish"
sudo apt-get upgrade
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y install docker.io
echo "Docker has been successfully installed."
sudo apt -y update
date +"%H:%M"
BIN_VERSION="1.4.0"
nproc=$(free -g | awk '/Mem:/{print $2}')
INPUT_DIR="$Ref"
OUTPUT_DIR="$cwd/Call_Variant_Files"
REF_FILE="/input/$Ref_Name"
BAM_FILE="/input/"$ID".RGG.sorted.marked.bam"  
OUTPUT_VCF="/output/"$ID"_Deep_tumor.vcf.gz"
OUTPUT_GVCF="/output/"$ID"_Deep_tumor.g.vcf.gz"
sudo docker pull google/deepvariant:"${BIN_VERSION}"
sudo docker pull gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}"
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}":"/output" \
  google/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=WES \
  --ref="${REF_FILE}" \
  --reads="${BAM_FILE}" \
  --output_vcf="${OUTPUT_VCF}" \
  --output_gvcf="${OUTPUT_GVCF}" \
  --num_shards=$(nproc)
date +"%H:%M"
sudo chmod -R u+rwX,g+rwX,o+rwX "$cwd/Call_Variant_Files"
}

Call_DeepVariant_RNA(){
Packages=( apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker-ce )
sudo apt-get -qq -y update
for pkg in "${Packages[@]}"; do
	if dpkg -s $pkg &> /dev/null
	then
		echo "$pkg is installed."
	else
		echo "$pkg is not installed. Installing $pkg..."
		sudo apt-get -qq -y install $pkg &> /dev/null
		echo "$pkg has been successfully installed."
	fi
done
mkdir -p model
# Check if model files exist before downloading
if [ ! -f "model/model.ckpt.data-00000-of-00001" ]; then
    curl https://storage.googleapis.com/deepvariant/models/DeepVariant/1.4.0/DeepVariant-inception_v3-1.4.0+data-rnaseq_standard/model.ckpt.data-00000-of-00001 > model/model.ckpt.data-00000-of-00001
fi
if [ ! -f "model/model.ckpt.example_info.json" ]; then
    curl https://storage.googleapis.com/deepvariant/models/DeepVariant/1.4.0/DeepVariant-inception_v3-1.4.0+data-rnaseq_standard/model.ckpt.example_info.json > model/model.ckpt.example_info.json
fi
if [ ! -f "model/model.ckpt.index" ]; then
    curl https://storage.googleapis.com/deepvariant/models/DeepVariant/1.4.0/DeepVariant-inception_v3-1.4.0+data-rnaseq_standard/model.ckpt.index > model/model.ckpt.index
fi
if [ ! -f "model/model.ckpt.meta" ]; then
    curl https://storage.googleapis.com/deepvariant/models/DeepVariant/1.4.0/DeepVariant-inception_v3-1.4.0+data-rnaseq_standard/model.ckpt.meta > model/model.ckpt.meta
fi
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
BIN_VERSION="1.4.0"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y install docker.io
sudo docker pull google/deepvariant:"${BIN_VERSION}"
sudo docker pull gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}"
echo "Docker has been successfully installed."
nproc=$(free -g | awk '/Mem:/{print $2}')
date +"%H:%M"
BIN_VERSION="1.4.0"
nproc=$(nproc)
INPUT_DIR="$Ref"
OUTPUT_DIR="$cwd/Call_Variant_Files"
REF_FILE="/input/$Ref_Name"
BAM_FILE="/input/"$ID".RGG.sorted.marked.bam"
OUTPUT_VCF="/output/"$ID"_Deep_tumor.vcf.gz"
OUTPUT_GVCF="/output/"$ID"_Deep_tumor.g.vcf.gz"
sudo docker pull google/deepvariant:"${BIN_VERSION}"
sudo docker pull gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}"
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}":"/output" \
  -v "$(pwd)/model":"/model" \
  google/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=WES \
  --customized_model=/model/model.ckpt \
  --ref="${REF_FILE}" \
  --reads="${BAM_FILE}" \
  --output_vcf="${OUTPUT_VCF}" \
  --num_shards="${nproc}" \
  --make_examples_extra_args="split_skip_reads=true"
date +"%H:%M"
sudo chmod -R u+rwX,g+rwX,o+rwX "$cwd/Call_Variant_Files"
}

Filter_VCF(){
if [ "$VariantCallerName" == "HC" ]; then 
	bcftools filter -O z -o "$cwd/Post_Processing/HAPLO_FIL_$ID.vcf.gz"  -i 'QUAL>200 && INFO/DP>=10 && GQ>=20' "$cwd/Call_Variant_Files/HAPLO$ID.vcf.gz"
	bcftools index $cwd/Post_Processing/"HAPLO_FIL_$ID.vcf.gz"
else 
	bcftools view -f PASS $cwd/Call_Variant_Files/$ID_Deep_RNA_tumor.vcf.gz  | bcftools view -O z  -i 'DP>=10 && QUAL>=20 && GQ>=20' -o $cwd/Post_Processing/"DV_FIL_$ID.vcf.gz"
	bcftools index $cwd/Post_Processing/"DV_FIL_$ID.vcf.gz" 
fi
}
filename=$1
# the "read" command is followed by the "||" operator and a condition that checks if the "line" variable is not empty. 
while read line || [ -n "$line" ]; do
  IFS=$'\t' read -r forward reverse ref index ID VariantCaller type <<< "$line"
  if [ ! -z "${ref}" ]; then
    # The user entered a value for the reference.
	Reference_File="$ref"
	else
	if [ ! -f /usr/local/bin/Homo_sapiens_assembly38.fasta ]; then
		wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta
		sudo mv Homo_sapiens_assembly38.fasta /usr/local/bin/Homo_sapiens_assembly38.fasta
	fi
	if [ ! -f /usr/local/bin/Homo_sapiens_assembly38.dict ]; then
		wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dict
		sudo mv Homo_sapiens_assembly38.dict /usr/local/bin/Homo_sapiens_assembly38.dict
	fi
	if [ ! -f /usr/local/bin/Homo_sapiens_assembly38.fasta.fai ]; then
		wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.fai
		sudo mv Homo_sapiens_assembly38.fasta.fai /usr/local/bin/Homo_sapiens_assembly38.fasta.fai
	fi
	Reference_File="/usr/local/bin/Homo_sapiens_assembly38.fasta"
  fi
Ref="$(dirname "$Reference_File")"
Ref_Name=$(basename "$Reference_File")
cwd=$(pwd)
mkdir -p $cwd/Fastp_files
mkdir -p $cwd/Aligned_files
mkdir -p $cwd/Processing_files
mkdir -p $cwd/Call_Variant_Files
mkdir -p $cwd/Post_Processing
VariantCallerName=$VariantCaller
datatype=$type
Pre_Processing
Call_Variant
Filter_VCF
done < $filename
echo "Analysis completed!"



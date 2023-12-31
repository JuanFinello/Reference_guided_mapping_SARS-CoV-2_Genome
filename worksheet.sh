#!/bin/bash

##############################################
# Reference_guided_mapping_SARS-CoV-2_Genome #
##############################################


### The following script is for the reference-guided mapping of a SARS-CoV-2 genome, starting from the FASTQ files and ending with the genome assembly through reference mapping.


### Samples were downloaded from https://www.ebi.ac.uk/ena/browser/view/PRJEB37886

# ERR10000020.fastq
# ERR10000020_1.fastq
# ERR10000020_2.fastq

# Samples were prepared at the Rosalind Franklin Laboratory by Donald Fraser, Suki Lee, Rob Howes, The Rosalind Franklin Laboratory, and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team.

# Organism: Severe acute respiratory syndrome coronavirus 2
# Sample Accession: SAMEA110427063
# Sample Title: COG-UK/LSPA-3EBED5E
# Center Name: Wellcome Sanger Institute
# Sample Alias: COG-UK/LSPA-3EBED5E
# Checklist: ERC000033
# Broker Name: SC
# ENA-CHECKLIST: ERC000033
# Host Health State: Not provided
# Host Scientific Name: Human
# Collection Date: 2022-07-05
# Sample Capture Status: Active surveillance in response to an outbreak
# Host Subject Id: Not provided
# Geographic Location (Region And Locality): Scotland
# Host Common Name: Human
# Host Sex: Not provided
# Isolate: Not provided
# Collector Name: Not provided
# ENA-FIRST-PUBLIC: 2022-07-28
# ENA-LAST-UPDATE: 2022-07-28
# Collecting Institution: Rosalind Franklin Laboratory
# Geographic Location (Country And/or Sea): United Kingdom


### PROCESSING FASTQ USING FASTQC PROGRAM

# FastQC aims to provide a simple way to perform some quality control checks on raw sequence data derived from high-throughput sequencing processes. It provides a modular set of analyses that you can use to quickly get an impression of whether your data has any issues that need to be taken into account before further analysis.

fastqc -o results/ ERR10000020_1.fastq.gz
fastqc -o results/ ERR10000020_2.fastq.gz

# UNZIPPING FILES

gzip -d ERR10000020_1.fastq.gz
gzip -d ERR10000020_2.fastq.gz

# CHECKING THE QUALITY SCORE FORMAT

head -n 4 ERR10000020_2.fastq

### PRINTSEQ TO CLEAN FASTQ FILES

# PRINSEQ can be used to filter, reformat, or trim your genomic and metagenomic sequence data. It generates summary statistics of your sequences in graphical and tabular format. It is easily configurable and provides a user-friendly interface.

prinseq-lite.pl -fastq ERR10000020_1.fastq -fastq2 ERR10000020_2.fastq -out_good good/ -out_bad bad/ -min_qual_mean 30 -trim_right 20 -trim_left 10

# REFERENCE MAPPING

# It is an approach to assemble a genome, it is useful for viruses like SarsCoV2 where we have a good reference genome. The goal is to obtain the consensus sequence.

# BWA is a software package for mapping low-divergent sequences against a large reference genome.
# First, I need a reference genome in FASTA format, and I will create an index for that genome.

mkdir BWA

# The following code generates 5 index files.

bwa index -p BWA/SarsCov2 WIV04_sars_cov_2.fasta

# LET'S ALIGN AND OBTAIN A SAM FILE, WHICH SHOULD BE NAMED THE SAME AS THE INPUT FASTQ + version of the aligned genome.
# BWA/SarsCov2 indicates the alignment; it is not necessary to include the prefix; the program interprets it automatically.

bwa mem -o BWA/ER1_SarSCoV2.sam BWA/SarsCov2 _1.fastq _2.fastq

### The SAM file is not sorted, for this, we use SAMTOOLS.

samtools sort -o XO910_SarSCov2.bam XO910_SarSCov2.sam

# The output is the sorted BAM file.
# The next step is to index the BAM file.

samtools index XO910_SarSCov2.bam

# The output is a .bam.bai file (XO910_SarSCov2.bam).
# To view the content of the BAM file, we also use samtools.

samtools view XO910_SarSCov2.bam

# To view the alignment, we can use IGV.


###VARIANT CALLING

# We read our BAM file and obtain all relevant and representative differences.
# The variant list is a VCF file that tells us which positions are different from the reference and what that difference is.
# Variant calling use the samtools mpileup command to generate a pileup file containing read alignments and base information at each genomic position.

bcftools mpileup -Ou -f sequence.fasta XO910_SarSCov2.bam | bcftools call -Ou -mv -o XO910_SarSCov2.bcf

# Call variants and convert to VCF: Use the bcftools call command to call variants based on the pileup information and convert the output to VCF format.

bcftools call -c XO910_SarSCov2.bcf > XO910_SarSCov2.vcf

# Compress the VCF file using bgzip: Run the following command to compress the VCF file and create a compressed file with the extension ".vcf.gz":

bgzip -c XO910_SarSCov2.vcf > XO910_SarSCov2.vcf.gz

# Index the compressed VCF file using tabix: Run the following command to create an index file (.csi or .tbi, they are the same) for the compressed VCF file:

tabix -p vcf XO910_SarSCov2.vcf.gz


### CONSENSUS SEQUENCE

# Generate the consensus sequence

bcftools consensus -f sequence.fasta -o fastasalida.fasta XO910_SarSCov2.vcf.gz


#### ASSEMBLY

ls -lh X0910_S249_R1_001.fastq
ls -lh X0910_S249_R1_001.fastq

# start with a pair of fastq files that have already been cleaned (without adapters or low-quality sequences).

# To determine the sequencing coverage, sum all the bases in the file and divide it by the size of the reference genome.

cat X0910_S249_R1_001.fastq X0910_S249_R2_001.fastq | paste - - - - | awk '{print $3}' | wc -m

cat X0910_S249_R1_001.fastq X0910_S249_R2_001.fastq | paste - - - - | awk '{print $3}' | pr -d '\n' | wc -m

coverage=$(echo $((76620495/30000))) # Coverage calculation: sum of bases divided by the size of the genome reference.

# Spades (one of the most commonly used programs for genome assemblies of any type, including a version for coronavirus assemblies).

mkdir resultsX09

spades.py --corona -t 1 -m 7 -1 X0910_S249_R1_001.fastq -2 X0910_S249_R2_001.fastq -0 resultsX09/

cd resultsX09

# To view the created scaffolds.

less scaffolds.fasta

grep -c '^>' scaffolds.fasta









### ANOTHER TYPE OF ASSEMBLY ### Assembly with reference using "Mira"

# Create a mira.conf file with the following commands:

project=sc2_0910
job=genome,mapping,accurate
parameters=COMMON_SETTINGS -GE:not=2:kpmf=10 \
-NW:cmrnl=no:cac=no -CO:fnic=yes \
-OUT:rtd=yes:orc=no:orm=no:orw=no:otm=no \
SOLEXA_SETTINGS -AS:mrl=1000 -CL:spx174=no

readgroup
is_reference
data=sc2_wuhan.fna
strain=ref

readgroup=X0910
data=X0910half_S249_R1_001.fastq.gz X0910half_S249_R2_001.fastq.gz
technology=solexa
# template_size = 150 450
segment_placement=---> <---
strain=wk

# Run the following command
mira mira.conf

# The output of this program consists of four blocks of sequences and two types of fasta files.
# One with the sequence and another with the quality of the sequence.
# We keep sc2_0910_d_results/sc2_0910_out_AllStrains.unpadded.fasta





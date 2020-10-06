#!/bin/env bash

# Biafra Ahanonu
# Script to setup MaxQuant in Anaconda on UCSF Wynton
# Started: ~2020.09.03 [00:08:28]

# Load Anaconda and required modules
module load Sali
module load anaconda

# Add proper channels to conda configuration
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

# Create maxquantTest Anaconda environment
conda create --name maxquantTest

# Initialize conda for bash
conda init bash

# Activate the maxquantTest environment
# conda activate maxquantTest
source activate maxquantTest

# Install maxquant and dependencies (like mono)
conda install maxquant

# Run MaxQuant, mqpar.xml can be generated using the MaxQuant GUI or by editing an existing XML file. This could also be made programmatic for automated runs or re-analysis.
# maxquant mqpar.xml
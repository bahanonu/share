#!/bin/env bash

# Biafra Ahanonu
# Script to run MaxQuant on a Wynton compute node.
# Started: 2020.09.03 [00:24:10]

echo "Script running on node $HOSTNAME"

# Load Anaconda and required modules
echo "Loading Sali"
module load Sali
echo "Loading anaconda"
module load anaconda

# Initialize conda for bash
echo "Initializing conda in bash"
conda init bash

# Activate the maxquantTest environment, we use "source" to avoid having to mess with conda init further.
echo "Activating maxquantTest Anaconda environment"
# conda activate maxquantTest
source activate maxquantTest

# Run MaxQuant, mqpar.xml can be generated using the MaxQuant GUI or by editing an existing XML file. This could also be made programmatic for automated runs or re-analysis.
echo "Running maxquant"
mqparPath=/wynton/home/YOUR_PATH/parameters/mqpar.xml
echo "Running MaxQuant XML file: $mqparPath."
maxquant $mqparPath
#!/bin/env bash

# Biafra Ahanonu
# Script to run MaxQuant on a Wynton compute node.
# Started: 2020.09.03 [00:24:10]

#######
# USER VARIABLES
condaEnvName=maxquantTest
mqparPath=/wynton/home/YOUR_PATH/parameters/mqpar.xml

#######

echo "Script running on node $HOSTNAME"
date +"%Y_%m_%d %H:%M:%S"

# Load Anaconda and required modules
echo "Loading Sali"
module load Sali
echo "Loading anaconda"
module load anaconda

# Initialize conda for bash
echo "Initializing conda in bash"
conda init bash

# Activate the Anaconda environment, we use "source" to avoid having to mess with conda init further.
echo "Activating $condaEnvName Anaconda environment"
# conda activate maxquantTest
source activate $condaEnvName
maxquant --version

# Run MaxQuant, mqpar.xml can be generated using the MaxQuant GUI or by editing an existing XML file. This could also be made programmatic for automated runs or re-analysis.
echo "Running maxquant"
echo "Running MaxQuant XML file: $mqparPath."
maxquant $mqparPath

date +"%Y_%m_%d %H:%M:%S"

## End-of-job summary, if running as a job
[[ -n "$JOB_ID" ]] && qstat -j "$JOB_ID"
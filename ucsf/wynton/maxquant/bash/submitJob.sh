#!/bin/env bash

# Biafra Ahanonu
# Script to submit MaxQuant job to Wynton scheduler.
# Started: ~2020.09.03 [00:08:28]
# Todo
	# Allow script to accept number of cores as an optional input

# -cwd current working directory
# -pe smp 32 - specify 32 cores on machine
# -l mem_free=4G - request 4GB per core
qsub -cwd -pe smp 32 -l mem_free=4G -l h_rt=24:00:00 runMaxQuant.sh
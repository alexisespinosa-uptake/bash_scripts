#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=minioMirror

dirToMirror="/scratch/pawsey0001/espinosa/manyFilesTest/root_5169208"
serviceAlias=magenta
newBucket="aeg-thousands-${SLURM_JOBID}"


echo "-- Quick list of existing buckets --------------------"
mc ls ${serviceAlias}/

echo "-- Creating the new bucket ---------------------------"
mc mb ${serviceAlias}/${newBucket}
mc ls ${serviceAlias}/

echo "-- Mirrowing directory into the new bucket -----------"
startTime=$(date +%s) 
mc mirror $dirToMirror ${serviceAlias}/${newBucket} 
endTime=$(date +%s)
lengthTime=$(expr $endTime - $startTime)
echo "Mirrowing time = $lengthTime"

echo "-- Script finished -----------------------------------"


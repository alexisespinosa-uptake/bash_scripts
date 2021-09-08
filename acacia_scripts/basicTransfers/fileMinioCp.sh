#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=fileMinioCopy

workingDir="/scratch/pawsey0001/espinosa/manyFilesTest"
fileToCopy="${workingDir}/manyMillions_01.tar"
serviceAlias=magenta
newBucket="aeg-tared-files-${SLURM_JOBID}"

echo "-- Quick list of existing buckets --------------------"
mc ls ${serviceAlias}/

echo "-- Creating the new bucket ---------------------------"
mc mb ${serviceAlias}/${newBucket}
mc ls ${serviceAlias}/

echo "-- mc cp <file> into the new bucket ------------------"
startTime=$(date +%s) 
mc cp ${fileToCopy} ${serviceAlias}/${newBucket} 
endTime=$(date +%s)
copyTime=$(expr $endTime - $startTime)
echo "mc cp time = $copyTime"

echo "-- Script finished -----------------------------------"


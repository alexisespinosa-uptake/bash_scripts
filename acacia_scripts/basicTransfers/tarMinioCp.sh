#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=tarMinioCopy

workingDir="/scratch/pawsey0001/espinosa/manyFilesTest"
dirToMirror="1millionTree_5171433"
serviceAlias=magenta
newBucket="aeg-tared-thousands-${SLURM_JOBID}"

echo "-- First taring the directory ------------------------"
cd $workingDir
taredFile="${dirToMirror}.tar.gz"
startTime=$(date +%s) 
tar -czvf ${taredFile} ${dirToMirror}
endTime=$(date +%s)
taringTime=$(expr $endTime - $startTime)
echo "Taring time = $taringTime"


echo "-- Quick list of existing buckets --------------------"
mc ls ${serviceAlias}/

echo "-- Creating the new bucket ---------------------------"
mc mb ${serviceAlias}/${newBucket}
mc ls ${serviceAlias}/

echo "-- mc cp <tared directory> into the new bucket -------"
startTime=$(date +%s) 
mc cp ${taredFile} ${serviceAlias}/${newBucket} 
endTime=$(date +%s)
copyTime=$(expr $endTime - $startTime)
echo "mc cp time = $copyTime"
totalTime=$(expr $taringTime + $copyTime)
echo "Total time = $totalTime"

echo "-- Script finished -----------------------------------"


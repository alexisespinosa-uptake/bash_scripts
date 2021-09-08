#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=tarRcloneCopy

workingDir="/scratch/pawsey0001/espinosa/manyFilesTest"
dirToMirror="1millionTree_5171433"
serviceAlias=magenta
newBucket="aeg-tared-thousands-${SLURM_JOBID}"

echo "-- Loading modules -----------------------------------"
module load rclone
module list

echo "-- Setting up the environment ------------------------"
export RCLONE_CONFIG_CEPH_TYPE="s3"
export RCLONE_CONFIG_CEPH_ENDPOINT="https://nimbus.pawsey.org.au:8080"
export RCLONE_CONFIG_CEPH_ACCESS_KEY_ID="2e67133ce9124d609e6adad2634ca124"
export RCLONE_CONFIG_CEPH_SECRET_ACCESS_KEY="44017d550461455aa4f6943ccaf22887"

echo "-- First taring the directory ------------------------"
cd $workingDir
taredFile="${dirToMirror}.tar.gz"
startTime=$(date +%s)
tar -czvf ${taredFile} ${dirToMirror}
endTime=$(date +%s)
taringTime=$(expr $endTime - $startTime)
echo "Taring time = $taringTime"

echo "-- rclone copy <tared directory> into the new bucket -"
startTime=$(date +%s) 
rclone copy $taredFile ceph:${newBucket}/$taredFile
endTime=$(date +%s)
copyTime=$(expr $endTime - $startTime)
echo "rclone copy time = $copyTime"
totalTime=$(expr $taringTime + $copyTime)
echo "Total time = $totalTime"

echo "-- Script finished -----------------------------------"


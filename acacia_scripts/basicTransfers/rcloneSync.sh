#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=rcloneSync

dirToMirror="/scratch/pawsey0001/espinosa/manyFilesTest/1millionTree_5171433"
dirName=$(basename $dirToMirror)
serviceAlias=magenta
newBucket="aeg-thousands-${SLURM_JOBID}"

echo "-- Loading modules -----------------------------------"
module load rclone
module list

echo "-- Setting up the environment ------------------------"
export RCLONE_CONFIG_CEPH_TYPE="s3"
export RCLONE_CONFIG_CEPH_ENDPOINT="https://nimbus.pawsey.org.au:8080"
export RCLONE_CONFIG_CEPH_ACCESS_KEY_ID="2e67133ce9124d609e6adad2634ca124"
export RCLONE_CONFIG_CEPH_SECRET_ACCESS_KEY="44017d550461455aa4f6943ccaf22887"

echo "-- Syncing directory into the new bucket -----------"
startTime=$(date +%s) 
rclone sync $dirToMirror ceph:${newBucket}
endTime=$(date +%s)
lengthTime=$(expr $endTime - $startTime)
echo "Syncing time = $lengthTime"

echo "-- Script finished -----------------------------------"


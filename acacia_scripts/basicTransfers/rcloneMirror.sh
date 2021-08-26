#!/bin/bash --login
#SBATCH --partition=copyq
#SBATCH --time=24:00:00
#SBATCH --ntasks=2
#SBATCH --job-name=rcloneSync

dirToMirror="/scratch/pawsey0001/espinosa/manyFilesTest/1millionFilesTree"
dirName=$(basename $dirToMirror)
serviceAlias=magenta
newBucket="aeg-thousands-${SLURM_JOBID}"

echo "-- Loading modules -----------------------------------"
module load rclone
module list

echo "-- Setting up the environment ------------------------"
export RCLONE_CONFIG_CEPH_TYPE="s3"
export RCLONE_CONFIG_CEPH_ENDPOINT="https://nimbus.pawsey.org.au:8080"
export RCLONE_CONFIG_CEPH_ACCESS_KEY_ID="35e659b07a0247bc803e8ca8673435ce"
export RCLONE_CONFIG_CEPH_SECRET_ACCESS_KEY="b3ffa8ce04bc467d8818877afe2b6e14"

#@@echo "-- Quick list of existing buckets --------------------"
#@@mc ls ${serviceAlias}/
#@@
#@@echo "-- Creating the new bucket ---------------------------"
#@@mc mb ${serviceAlias}/${newBucket}
#@@mc ls ${serviceAlias}/

echo "-- Syncing directory into the new bucket -----------"
startTime=$(date +%s) 
#@@mc mirror $dirToMirror ${serviceAlias}/${newBucket} 
rclone sync $dirToMirror ceph:${newBucket}/${dirName}
endTime=$(date +%s)
lengthTime=$(expr $endTime - $startTime)
echo "Syncing time = $lengthTime"

echo "-- Script finished -----------------------------------"


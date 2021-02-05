#!/bin/bash --login
#SBATCH --job-name=count-short
#SBATCH -p copyq
#SBATCH --export=none
#SBATCH --time=24:00:00

thisUser=espinosa
logShort=log.count.${thisUser}.short

echo "Starting count clean" > $logShort
for gg in $(groups); do
   echo "Counting in /group/$gg" | tee -a $logShort
   find /group/$gg -type f -user $thisUser | wc - | tee -a $logShort
done

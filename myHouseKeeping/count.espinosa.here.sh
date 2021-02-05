#!/bin/bash --login
#SBATCH --job-name=count-here
#SBATCH -p copyq
#SBATCH --export=none
#SBATCH --time=24:00:00

dirToCount=/group/pawsey0001/espinosa
logFile=log.pawsey0001.espinosa

echo "Starting count clean" > $logFile

for dd in $(ls -d $dirToCount/*); do
   echo "Counting in $dd" | tee -a $logFile
   find $dd -type f -user espinosa | wc - | tee -a $logFile
done

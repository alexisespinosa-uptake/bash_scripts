#!/bin/bash --login
#SBATCH --job-name=count-long
#SBATCH -p copyq
#SBATCH --export=none
#SBATCH --time=24:00:00

thisUser=espinosa
logLong=log.count.${thisUser}.long

echo "Starting count clean" > $logLong
for gg in $(groups); do
   echo "Exploring in /group/$gg/${thisUser}" | tee -a $logLong
   for dd in $(ls -d /group/$gg/${thisUser}/*); do
      echo "Counting in $dd" | tee -a $logLong
      find $dd -type f -user ${thisUser} | wc - | tee -a $logLong
   done
   echo "Exploring in /group/$gg/software" | tee -a $logLong
   for dd in $(ls -d /group/$gg/software/*); do
      echo "Counting in $dd" | tee -a $logLong
      find $dd -type f -user ${thisUser} | wc - | tee -a $logLong
   done
done


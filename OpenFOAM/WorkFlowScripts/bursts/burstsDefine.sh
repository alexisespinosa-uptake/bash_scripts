#!/bin/bash
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#In this script we define the size of each of the bursts that had ran already
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript3=burstsDefine.sh
echo "currentScript3=$currentScript3"
errorCode3=300

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#THE FOLLOWING VARIABLES AND PARAMETERS NEED TO BE DEFINED IN THE MAIN SCRIPT WITH ADEQUATE VALUES
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Reconstruction parameters
echo "-----------------------------------------------------------"
echo "Recontruction parameters were set in the main script:"
echo "performReconstruct = ${performReconstruct}"
echo "memPerReconstruct = ${memPerReconstruct}, units are Gb"
echo "totalmemPerNodeReconstruct = ${totalMemPerNodeReconstruct}, units are Gb"
echo "numReconstructsPerJob = ${numReconstructsPerJob}"
echo "WorkFlowScriptsDir = ${WorkFlowScriptsDir}"
echo "workingDir = ${workingDir}"
echo "-----------------------------------------------------------"
if [[ -z "$performReconstruct" ]] ||
   [[ -z "$memPerReconstruct" ]] ||
   [[ -z "$totalMemPerNodeReconstruct" ]] ||
   [[ -z "$numReconstructsPerJob" ]] ||
   [[ -z "$WorkFlowScriptsDir" ]] ||
   [[ -z "$workingDir" ]]; then
   echo "Some of the above variables were not defined correctly in the main script:"
   echo "Exiting from $currentScript3"
   echo "-----------------------------------------------------------"
   ((errorCode3 += 1))
   exit $errorCode3
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#TarDecomposed parameters
echo "-----------------------------------------------------------"
echo "TarDecomposed parameters were set in the main script:"
echo "performTarDecomposed = ${performTarDecomposed}"
echo "memPerTarDecomposed = ${memPerTarDecomposed}, units are Gb"
echo "totalmemPerNodeTarDecomposed = ${totalMemPerNodeTarDecomposed}, units are Gb"
echo "maxTarDecomposedPerNode = ${maxTarDecomposedPerNode}"
echo "nodesPerTarDecomposedJob = ${nodesPerTarDecomposedJob}"
echo "WorkFlowScriptsDir = ${WorkFlowScriptsDir}"
echo "workingDir = ${workingDir}"
echo "-----------------------------------------------------------"
if [[ -z "$performTarDecomposed" ]] ||
   [[ -z "$memPerTarDecomposed" ]] ||
   [[ -z "$totalMemPerNodeTarDecomposed" ]] ||
   [[ -z "$maxTarDecomposedPerNode" ]] ||
   [[ -z "$nodesPerTarDecomposedJob" ]] ||
   [[ -z "$WorkFlowScriptsDir" ]] ||
   [[ -z "$workingDir" ]]; then
   echo "Some of the above variables were not defined correctly in the main script:"
   echo "Exiting from $currentScript3"
   echo "-----------------------------------------------------------"
   ((errorCode3 += 1))
   exit $errorCode3
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#DeleteDecomposed parameters
echo "-----------------------------------------------------------"
echo "DeleteDecomposed parameters were set in the main script:"
echo "performDeleteDecomposed = ${performDeleteDecomposed}"
echo "allStartTime = ${allStartTime}"
echo "maxDeleteDecomposedPerNode = ${maxDeleteDecomposedPerNode}"
echo "nodesPerDeleteDecomposedJob = ${nodesPerDeleteDecomposedJob}"
echo "nAliveTimes = ${nAliveTimes}"
echo "sleepTime = ${sleepTime}"
echo "WorkFlowScriptsDir = ${WorkFlowScriptsDir}"
echo "workingDir = ${workingDir}"
echo "-----------------------------------------------------------"
if [[ -z "$performDeleteDecomposed" ]] ||
   [[ -z "$allStartTime" ]] ||
   [[ -z "$maxDeleteDecomposedPerNode" ]] ||
   [[ -z "$nodesPerDeleteDecomposedJob" ]] ||
   [[ -z "$nAliveTimes" ]] ||
   [[ -z "$sleepTime" ]] ||
   [[ -z "$WorkFlowScriptsDir" ]] ||
   [[ -z "$workingDir" ]]; then
   echo "Some of the above variables were not defined correctly in the main script:"
   echo "Exiting from $currentScript3"
   echo "-----------------------------------------------------------"
   ((errorCode3 += 1))
   exit $errorCode3
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINTION OF THE AUXILIARY FUNCTIONS
source $WorkFlowScriptsDir/defineAuxiliaryFunctions.sh

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#Arguments, Variables and Directories
jobTagBurst=${jobTagBurst:-"NoTag"}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#CREATING THE LIST OF TIMES OF THE LAST BURST 

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Generating a list of existing time directories
echo "Reading a list of existing time directories" | tee -a ${logJob}
cd $workingDir/processor0
ls -dt [0-9]*/ | sed 's/\///g' > /tmp/listaDirsB.$SLURM_JOBID
sort -rn /tmp/listaDirsB.$SLURM_JOBID -o /tmp/listaDirsOrdenadaB.$SLURM_JOBID
i=0
while read textTimeDir; do
   timeDirArr[$i]=$textTimeDir
   echo "The $i timeDir is: ${timeDirArr[$i]}" | tee -a ${logJob}
   ((i++))
done < /tmp/listaDirsOrdenadaB.$SLURM_JOBID
nTimeDirectories=$i
if [ $nTimeDirectories -eq 0 ]; then
   echo "Exiting because NO time directories available for the case" | tee -a ${logJob}
   echo "Exiting from $currentScript3"
   ((errorCode3 += 2))
   exit $errorCode3
else
   maxTimeSeen=${timeDirArr[0]}
   echo "The maxTimeSeen is $maxTimeSeen" | tee -a ${logJob}
fi


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Generating a list of existing bursts
#AEG: This directory needs to be two levels deep in order to avoid numbering confusion with the 
#     find commands for deleting files from the processor* directories
burstsDir=$workingDir/bursts/lists
echo "Reading a list of existing burst directories" | tee -a ${logJob}
! [ -d $burstsDir ] && mkdir -p $burstsDir
cd $burstsDir
ls -dt [0-9]*/ | sed 's/\///g' > /tmp/listaBursts.$SLURM_JOBID
sort -rn /tmp/listaBursts.$SLURM_JOBID -o /tmp/listaBurstsOrdenada.$SLURM_JOBID
i=0
while read textBursts; do
   burstsArr[$i]=$textBursts
   echo "The $i burst is: ${burstsArr[$i]}" | tee -a ${logJob}
   ((i++))
done < /tmp/listaBurstsOrdenada.$SLURM_JOBID
nBurstsDirectories=$i
if [ $nBurstsDirectories -eq 0 ]; then
   echo "No bursts identified yet" | tee -a ${logJob}
   lastBurst=-1
   lastBurstedTime=-1
else
   lastBurst=${burstsArr[0]}
   i=0
   while read textTimes; do
      burstsTimeArr[$i]=$textTimes
      lastBurstedTime=${burstsTimeArr[$i]}
      echo "The $i bursted time is: ${lastBurstedTime}" | tee -a ${logJob}
      ((i++))
   done < ./$lastBurst/timesBurst.list
   nTimesBurstedLast=$i
fi
echo "The lastBurst existing is $lastBurst" | tee -a ${logJob}
echo "The lastBurstedTime is $lastBurstedTime" | tee -a ${logJob}


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Adding times for the next burst 
if float_cond "$maxTimeSeen > $lastBurstedTime"; then
   cd $burstsDir
   newBurst=$(( $lastBurst + 1 ))
   echo "Creating the next burst=$newBurst"
   mkdir $newBurst
   cd $newBurst
   touch timesBurst.list
   echo "Starting with the second last existing time, as the last time may be faulty"
   i=1
   timeI=${timeDirArr[$i]}
   echo "Up to time=$timeI"
   while float_cond "$timeI > $lastBurstedTime"; do
       echo $timeI >> timesBurst.list
       ((i++))
       timeI=${timeDirArr[$i]}
   done
   sort -n timesBurst.list -o timesBurst.list
   cd $burstsDir
   if (( $i == 1 )); then
       echo "The second last existing time ($timeI) is already included in the latest existing burst"
       echo "So, indeed, no new burst will be created."
       echo "Removing the last burst attempt with a no times on it: $newBurst"
       echo "Time=${timeDirArr[0]} was not considered as its the last time and could be faulty"
       rm -rf $newBurst
   else
       chmod 444 $newBurst/timesBurst.list
   fi
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINING THE BURSTS AND SUBMITTING RECURSIVE RECONSTRUCT
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Generating a final list of existing bursts and starting reconstructions
echo "Reading a list of existing burst directories" | tee -a ${logJob}
cd $burstsDir
ls -dt [0-9]*/ | sed 's/\///g' > /tmp/listaBursts2.$SLURM_JOBID
sort -rn /tmp/listaBursts2.$SLURM_JOBID -o /tmp/listaBurstsOrdenada2.$SLURM_JOBID
cd $workingDir
i=0
while read textBursts; do
   burstsArr[$i]=$textBursts
   burstDealingDir=$burstsDir/${burstsArr[$i]}
   echo "The $i burst is: ${burstsArr[$i]}" | tee -a ${logJob}
   if ! [ -f $burstDealingDir/.fullyReconstructed ] && [ $performReconstruct == "true" ]; then
      recJobName=rec-$jobTagBurst-${burstsArr[$i]}
      echo "Sending a job for reconstructing the bursted times"
      sbatch --export="burstDealingHere=${burstsArr[$i]},performReconstruct=$performReconstruct,allStartTime=$allStartTime,WorkFlowScriptsDir=$WorkFlowScriptsDir" --mem-per-cpu="${memPerReconstruct}G" --ntasks="$numReconstructsPerJob" --job-name=$recJobName --output="$burstsDir/${burstsArr[$i]}/${recJobName}-%j.out" $WorkFlowScriptsDir/burstsReconstruct.sh
   fi
   if ! [ -f $burstDealingDir/.fullyTaredDecomposed ] && [ $performTarDecomposed == "true" ]; then
      ! [ -d $workingDir/taredDecomposed ] && mkdir $workingDir/taredDecomposed
      tarDecomposedJobName=tarDeco-$jobTagBurst-${burstsArr[$i]}
      echo "Sending a job for taring the Decomposed bursted times"
      sbatch --export="burstDealingHere=${burstsArr[$i]},performTarDecomposed=$performTarDecomposed,WorkFlowScriptsDir=$WorkFlowScriptsDir" --mem-per-cpu="${memPerTarDecomposed}G" --ntasks="$maxTarDecomposedPerNode" --job-name=$tarDecomposedJobName --output="$burstsDir/${burstsArr[$i]}/${tarDecomposedJobName}-%j.out" $WorkFlowScriptsDir/burstsTarDecomposed.sh
   fi
   if ! [ -f $burstDealingDir/.fullyDeletedDecomposed ] && [ $performDeleteDecomposed == "true" ]; then
      deleteDecomposedJobName=delDeco-$jobTagBurst-${burstsArr[$i]}
      echo "Sending a job for deleting the Decomposed bursted times"
      sbatch --export="burstDealingHere=${burstsArr[$i]},performDeleteDecomposed=$performDeleteDecomposed,nAliveTimes=$nAliveTimes,sleepTime=$sleepTime,WorkFlowScriptsDir=$WorkFlowScriptsDir" --ntasks=$maxDeleteDecomposedPerNode --job-name=$deleteDecomposedJobName --output="$burstsDir/${burstsArr[$i]}/${deleteDecomposedJobName}-%j.out" $WorkFlowScriptsDir/burstsDeleteDecomposed.sh
   fi
   ((i++))
done < /tmp/listaBurstsOrdenada2.$SLURM_JOBID
nBurstsDirectories=$i
if [ $nBurstsDirectories -eq 0 ]; then
   echo "No bursts identified yet" | tee -a ${logJob}
   lastBurst=-1
   lastBurstedTime=-1
fi


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP
echo "The definition of bursts and submission of reconstruction,taring and deletion jobs have finished"
echo "Finishing $currentScript3"

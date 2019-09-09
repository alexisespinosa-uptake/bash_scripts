#!/bin/bash -l
#SBATCH --export=none
#SBATCH --account=pawsey0224
#SBATCH --job-name=burstsReconstruct
#SBATCH --partition=workq
#SBATCH --clusters=zeus
#--------OJOTEST: Change to 24 hours after finishing testing
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=1G
#SBATCH --output=%x-%j.out

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#RECURSIVE SCRIPT FOR RECONSTRUCTING ALL THE DECOMPOSED TIMES IN A BURST LIST
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript4=`squeue -h -j $SLURM_JOBID -o %o`
echo "currentScript4=${currentScript4}"
errorCode4='400'

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#SETTING UP THE ENVIRONMENT AND VARIABLES

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Setting up the modules
module list
source defineModulesForZeus.sh
module list

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Spitting the slurm setup
echo "SLURM_JOB_ID = $SLURM_JOB_ID"
echo "SLURM_JOB_NAME = $SLURM_JOB_NAME"
echo "SLURM_NTASKS = $SLURM_NTASKS"
echo "SLURM_NTASKS_PER_NODE = $SLURM_NTASKS_PER_NODE"
echo "SLURM_JOB_NUM_NODES=$SLURM_JOB_NUM_NODES"
echo "SLURM_MEM_PER_CPU = $SLURM_MEM_PER_CPU"

echo $'And everything: \n'
scontrol show job $SLURM_JOB_ID

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
##Receiving parameters or setting defaults
burstDealingHere=${burstDealingHere:-"-1"}
performReconstruct=${performReconstruct:-"true"}
#recJobName=${recJobName:-"$SLURM_JOB_NAME"}
#Working Directories
WorkFlowScriptsDir=${WorkFlowScriptsDir:-"$MYGROUP/bash_scripts/OpenFOAM/WorkFlowScripts/bursts"}
workingDir=${SLURM_SUBMIT_DIR:-$PWD}
dependantScript=${currentScript4}

echo "Directory for the scripts WorkFlowScriptsDir=$WorkFlowScriptsDir"
echo "Case workingDir=$workingDir"
echo "Burst of times burstDealingHere=$burstDealingHere"
echo "The performReconstruct=$performReconstruct"
echo "Dependant script will be: $dependantScript"
echo "The reconstruction job name is: $SLURM_JOB_NAME"
echo "The memory to be used per reconstruction is: $SLURM_MEM_PER_CPU in Gb"

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Exiting if performReconstruct is not true
if [ $performReconstruct != "true" ]; then
   echo "Exiting early because performReconstruct=$performReconstruct is not \"true\""
   echo "And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript4"
   ((errorCode4 += 0))
   exit $errorCode4
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINTION OF THE AUXILIARY FUNCTIONS
source $WorkFlowScriptsDir/defineAuxiliaryFunctions.sh


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#CHECKING THE LOGIC FOR DECIDING IF KEEP RUNNING THIS SCRIPT WITHOUT DUPLICATES
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Identifying if is there another job with the same name already running
nNamesakes=$(squeue --name="$SLURM_JOB_NAME" --state=RUNNING | wc -l)
nNamesakes=$(float_eval "$nNamesakes")
nNamesakes=$(float_eval "$nNamesakes - 2")

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there are other pending jobs with the same name
nPendings=$(squeue --name="$SLURM_JOB_NAME" --state=PENDING | wc -l)
nPendings=$(float_eval "$nPendings")
nPendings=$(float_eval "$nPendings - 1")

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Logic for cancelling existing running and pending jobs and resubmitting
if [ $nNamesakes -ge 2 ] || [ $nPendings -ge 2 ]; then
   echo "TWO OR MORE jobs with the same name: \"${SLURM_JOB_NAME}\" are already running. Namesakes=${nNamesakes}"
   echo "or TWO OR MORE jobs with the same name are already pending. nPendingis=${nPendings}"
   echo "All the existing jobs (all running and all pending) with the same name will be cancelled"
   scancel --name="$SLURM_JOB_NAME"
   echo "All Namesake-Jobs (running and pending) have been cancelled"
   echo "Now, This job will be proceed to submit a case for running"
elif [ $nNamesakes -eq 1 ] && [ $nPendings -le 1 ]; then
   echo "ONE job with the same name: \"{SLURM_JOB_NAME}\" is already running. Namesakes=${nNamesakes}"
   echo "And one or none jobs with the same name are already pending. nPendings=${nPendings}"
   echo "Everything looks fine in the queue for that running job and dependants."
   echo "So That job will be left running"
   echo "And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript4"
   ((errorCode4 += 1))
   exit $errorCode4
elif [ $nNamesakes -eq 0 ] && [ $nPendings -eq 1 ]; then
   echo "There was a single orphan pending job with the same name: \"{SLURM_JOB_NAME}\". Namesakes=${nNamesakes}, nPendingis${nPendings}"
   echo "I will leave that in the queue And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript4"
   ((errorCode4 += 2))
   exit $errorCode4
else
   echo "No Namesake-Jobs already running exist. Good! Namesakes=${nNamesakes}, nPendings=${nPendings}"
   echo "Now, This job is free to resubmit itself if neccessary."
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Avoiding falling into an infinite loop of recurrent errors which generate huge amount of files
maxSlurmies=25
cd $workingDir
slurmies=$(find . -maxdepth 1 -name "${SLURM_JOB_NAME}*.out" | wc -l)
if [ $slurmies -gt $maxSlurmies ]; then
   echo "Exiting because the maximum outputfiles have been reached: $slurmies>$maxSlurmies" 
   echo "Check in directory $PWD"
   echo "Exiting from $currentScript4"
   ((errorCode4 += 3))
   exit $errorCode4
fi
slurmies=$(find ./bursts/lists/$burstDealingHere -maxdepth 1 -name "${SLURM_JOB_NAME}*.out" | wc -l)
if [ $slurmies -gt $maxSlurmies ]; then
   echo "Exiting because the maximum outputfiles have been reached: $slurmies>$maxSlurmies" 
   echo "Check in directory $PWD/bursts/lists/$burstDealingHere"
   echo "Exiting from $currentScript4"
   ((errorCode4 += 4))
   exit $errorCode4
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINING THE RECONSTRUCTION DIRECTORIES

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there is any decomposition
cd $workingDir
echo $PWD
if [ -d processor0 ]; then
   echo "Directory processor0 is here. Good! will attempt reconstruction."
else
   echo "Processor0 does not exists. Exiting"
   echo "Exiting from $currentScript4"
   ((errorCode4 += 5))
   exit $errorCode4
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Reading the list of times to reconstruct
i=0
while read textTimeDir
do
    timeDirArr[$i]=$textTimeDir
    #echo "The $i timeDir is: ${timeDirArr[$i]}"
    ((i++))
done < $workingDir/bursts/lists/${burstDealingHere}/timesBurst.list
nTimeDirectories=$i
if [ $nTimeDirectories -eq 0 ]
then
   echo "Exiting because NO time directories indicated for reconstruct"
   echo "Exiting from $currentScript4"
   ((errorCode4 += 6))
   exit $errorCode4
else
   jIni=0
   jEnd=$((nTimeDirectories - 1))
   maxTimeSeen=${timeDirArr[$jEnd]}
   minTimeSeen=${timeDirArr[$jIni]}
   echo "The maxTimeSeen is $maxTimeSeen"
   echo "The minTimeSeen is $minTimeSeen"
fi


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#EXECUTING THE RECONSTRUCTION OF THE CURRENT BURST AND SENDING THIS SCRIPT RECURSIVELY 
#-----------------------------------------
#-----------------------------------------
if ! [ -f $workingDir/bursts/lists/${burstDealingHere}/.fullyReconstructed ]; then
   #Reconstructing the desired directories
   dependantSent=false
   echo "Reconstructing all times without the .reconstructed file"
   cd $workingDir
   burstsDir=$workingDir/bursts/lists
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if [ -f "./${jTime}/.reconstructed" ]; then
          echo "NOT Reconstructing ${jTime} as it was done already"
       else
          if [ "$dependantSent" == "false" ]; then
             echo "Sending a dependant job to keep the reconstruction cycle of burst $burstDealingHere alive"
             next_jobid=$(sbatch --export="burstDealingHere=${burstDealingHere},performReconstruct=$performReconstruct" --mem-per-cpu=$SLURM_MEM_PER_CPU --ntasks=$SLURM_NTASKS --job-name=$SLURM_JOB_NAME --output="$burstsDir/${burstDealingHere}/${SLURM_JOB_NAME}-%j.out" --dependency=afterany:${SLURM_JOB_ID} $dependantScript | awk '{print $4}')
             scontrol show job $next_jobid
             squeue -u $USER
             dependantSent=true
          fi
          echo "YES Reconstructing ${jTime}"
          echo "Sending the reconstruction recursively in the background"
          Rlog=$workingDir/bursts/lists/${burstDealingHere}/Recons-${jTime}.log
          rm $Rlog
          srun --export="all,jTime=$jTime" -n 1 --mem-per-cpu=$SLURM_MEM_PER_CPU --exclusive --output=$Rlog $WorkFlowScriptsDir/singleReconstruct.sh &
       fi
   done
   wait
   #-----------------------------------------
   #-----------------------------------------
   #Checking if the burst recontruction has been completed
   echo "Checking if the burst recontruction has been completed"
   cd $workingDir
   fullyReconstructed="true"
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if ! [ -f "./${jTime}/.reconstructed" ]; then
          echo "Still ${jTime} in burst ${burstDealingHere} needs to be reconstructed"
          fullyReconstructed="false"
      fi
   done
   if [ $fullyReconstructed == "true" ]; then
      touch "$burstsDir/${burstDealingHere}/.fullyReconstructed"
      echo "Burst in $burstsDir has been fully reconstructed"
   fi
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP

echo "Reconstruct cycle script for burst list $burstDealingHere finished"
echo "Finishing $currentScript4"

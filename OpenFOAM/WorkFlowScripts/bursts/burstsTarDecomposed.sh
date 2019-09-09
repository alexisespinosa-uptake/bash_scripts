#!/bin/bash -l
#SBATCH --export=none
#SBATCH --account=pawsey0224
#SBATCH --job-name=burstsTarDecomposed
#SBATCH --partition=copyq
#SBATCH --clusters=zeus
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=1G
#SBATCH --output=%x-%j.out

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#RECURSIVE SCRIPT FOR TARING ALL THE DECOMPOSED TIMES IN A BURST LIST
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript5=`squeue -h -j $SLURM_JOBID -o %o`
echo "currentScript5=${currentScript5}"
errorCode5='500'

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
performTarDecomposed=${performTarDecomposed:-"true"}
#tarDecomposedJobName=${tarDecomposedJobName:-"$SLURM_JOB_NAME"}
#Working Directories
WorkFlowScriptsDir=${WorkFlowScriptsDir:-"$MYGROUP/bash_scripts/OpenFOAM/WorkFlowScripts/bursts"}
workingDir=${SLURM_SUBMIT_DIR:-$PWD}
dependantScript=${currentScript5}

echo "Directory for the scripts WorkFlowScriptsDir=$WorkFlowScriptsDir"
echo "Case workingDir=$workingDir"
echo "Burst of times burstDealingHere=$burstDealingHere"
echo "The performTarDecomposed=$performTarDecomposed"
echo "Dependant script will be: $dependantScript"
echo "The taringDecomposed job name is: $SLURM_JOB_NAME"
echo "And the memory to be used per taringDecomposed is: $SLURM_MEM_PER_CPU in Gb"

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Exiting if performTarDecomposed is not true
if [ $performTarDecomposed != "true" ]; then
   echo "Exiting early because performTarDecomposed=$performTarDecomposed is not \"true\""
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
   echo "Exiting from $currentScript5"
   ((errorCode5 += 1))
   exit $errorCode5
elif [ $nNamesakes -eq 0 ] && [ $nPendings -eq 1 ]; then
   echo "There was a single orphan pending job with the same name: \"{SLURM_JOB_NAME}\". Namesakes=${nNamesakes}, nPendingis${nPendings}"
   echo "I will leave that in the queue And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript5"
   ((errorCode5 += 2))
   exit $errorCode5
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
   echo "Exiting from $currentScript5"
   ((errorCode5 += 3))
   exit $errorCode5
fi
slurmies=$(find ./bursts/lists/$burstDealingHere -maxdepth 1 -name "${SLURM_JOB_NAME}*.out" | wc -l)
if [ $slurmies -gt $maxSlurmies ]; then
   echo "Exiting because the maximum outputfiles have been reached: $slurmies>$maxSlurmies" 
   echo "Check in directory $PWD/bursts/lists/$burstDealingHere"
   echo "Exiting from $currentScript5"
   ((errorCode5 += 4))
   exit $errorCode5
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINING THE TAR DECOMPOSED DIRECTORIES

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there is any decomposition
cd $workingDir
echo $PWD
if [ -d processor0 ]; then
   echo "Directory processor0 is here. Good! will attempt tar decomposed times."
else
   echo "Processor0 does not exists. Exiting"
   echo "Exiting from $currentScript5"
   ((errorCode5 += 5))
   exit $errorCode5
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Reading the list of times to tar
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
   echo "Exiting because NO time directories indicated for taring"
   echo "Exiting from $currentScript5"
   ((errorCode5 += 6))
   exit $errorCode5
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
#EXECUTING THE TARING OF THE CURRENT BURST AND SENDING THIS SCRIPT RECURSIVELY 
#-----------------------------------------
#-----------------------------------------
if ! [ -f $workingDir/bursts/lists/${burstDealingHere}/.fullyTaredDecomposed ]; then
   #taring the desired directories
   dependantSent=false
   echo "Taring all times without the TIME.taredDecomposed file"
   cd $workingDir
   burstsDir=$workingDir/bursts/lists
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if [ -f "./taredDecomposed/checks/${jTime}.taredDecomposed" ]; then
          echo "NOT Taring ${jTime} as it was done already"
       else
          if [ "$dependantSent" == "false" ]; then
             echo "Sending a dependant job to keep the Taring cycle of burst $burstDealingHere alive"
             next_jobid=$(sbatch --export="burstDealingHere=${burstDealingHere},performTarDecomposed=$performTarDecomposed" --mem-per-cpu=$SLURM_MEM_PER_CPU --ntasks=$SLURM_NTASKS --job-name=$SLURM_JOB_NAME --output="$burstsDir/${burstDealingHere}/${SLURM_JOB_NAME}-%j.out" --dependency=afterany:${SLURM_JOB_ID} $dependantScript | awk '{print $4}')
             scontrol show job $next_jobid
             squeue -u $USER
             dependantSent=true
          fi
          echo "YES Taring ${jTime}"
          echo "Sending the taring recursively in the background"
          Rlog=$workingDir/bursts/lists/${burstDealingHere}/TarDeco-${jTime}.log
          rm $Rlog
          srun --export="all,jTime=$jTime" -n 1 --mem-per-cpu=$SLURM_MEM_PER_CPU --exclusive --output=$Rlog $WorkFlowScriptsDir/singleTarDecomposed.sh &
       fi
   done
   wait
   #-----------------------------------------
   #-----------------------------------------
   #Checking if the burst taring has been completed
   echo "Checking if the burst taring has been completed"
   cd $workingDir
   fullyTared="true"
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if ! [ -f "./taredDecomposed/checks/${jTime}.taredDecomposed" ]; then
          echo "Still ${jTime} in burst ${burstDealingHere} needs to be taredDecomposed"
          fullyTared="false"
      fi
   done
   if [ $fullyTared == "true" ]; then
      touch "$burstsDir/${burstDealingHere}/.fullyTaredDecomposed"
      echo "Burst in $burstsDir has been fully taredDecomposed"
   fi
fi


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP

echo "Tar Decomposed cycle script for burst list $burstDealingHere finished"
echo "Finishing $currentScript5"

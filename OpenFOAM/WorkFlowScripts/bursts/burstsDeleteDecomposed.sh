#!/bin/bash -l
#SBATCH --export=none
#SBATCH --account=pawsey0001
#SBATCH --job-name=burstsDeleteDecomposed
#SBATCH --partition=copyq
#SBATCH --clusters=zeus
#--------OJOTEST: Change to 4-24 hours after finishing testing
####SBATCH --time=00:30:00
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
####SBATCH --mem-per-cpu=4G
#SBATCH --output=%x-%j.out

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#RECURSIVE SCRIPT FOR DELETING ALL THE DECOMPOSED TIMES IN A BURST LIST
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript6=`squeue -h -j $SLURM_JOBID -o %o`
echo "currentScript6=${currentScript6}"
errorCode6='600'

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
allStartTime=${allStartTime:-"0"}
burstDealingHere=${burstDealingHere:-"-1"}
performDeleteDecomposed=${performDeleteDecomposed:-"true"}
nAliveTimes=${nAliveTimes:-"3"}
sleepTime=${sleepTime:-"10m"}
previousMaxTimeSeen=${previousMaxTimeSeen:-"-1"}
#maxDeleteDecomposedPerNode=${maxDeleteDecomposedPerNode:-"2"}
#deletDecomposedJobName=${deletDecomposedJobName:-"$SLURM_JOB_NAME"}
#Working Directories
WorkFlowScriptsDir=${WorkFlowScriptsDir:-"$MYGROUP/bash_scripts/OpenFOAM/WorkFlowScripts/bursts"}
workingDir=${SLURM_SUBMIT_DIR:-$PWD}
dependantScript=${currentScript6}

echo "Directory for the scripts WorkFlowScriptsDir=$WorkFlowScriptsDir"
echo "Case workingDir=$workingDir"
echo "Burst of times burstDealingHere=$burstDealingHere"
echo "The performDeleteDecomposed=$performDeleteDecomposed"
echo "The number of left-alive times is nAliveTimes=$nAliveTimes"
echo "The sleep time if no deletion was made is sleepTime=$sleepTime"
echo "The previousMaxTimeSeen was previousMaxTimeSeen=$previousMaxTimeSeen"
#echo "The maxDeleteDecomposedPerNode=$maxDeleteDecomposedPerNode"
echo "Dependant script will be: $dependantScript"
echo "The deletingDecomposed job name is: $SLURM_JOB_NAME"
echo "And the memory to be used per deletingDecomposed is: $SLURM_MEM_PER_CPU in Gb"

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Exiting if performDeleteDecomposed is not true
if [ $performDeleteDecomposed != "true" ]; then
   echo "Exiting early because performDeleteDecomposed=$performDeleteDecomposed is not \"true\""
   echo "And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript6"
   ((errorCode6 += 0))
   exit $errorCode6
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
echo "From $currentScript6, nNamesakes=$nNamesakes"

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there are other pending jobs with the same name
nPendings=$(squeue --name="$SLURM_JOB_NAME" --state=PENDING | wc -l)
nPendings=$(float_eval "$nPendings")
nPendings=$(float_eval "$nPendings - 1")
echo "From $currentScript6, nPendings=$nPendings"

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
   echo "Exiting from $currentScript6"
   ((errorCode6 += 1))
   exit $errorCode6
elif [ $nNamesakes -eq 0 ] && [ $nPendings -eq 1 ]; then
   echo "There was a single orphan pending job with the same name: \"{SLURM_JOB_NAME}\". Namesakes=${nNamesakes}, nPendingis${nPendings}"
   echo "I will leave that in the queue And This job request will be cancelled"
   echo "Exiting this job request .."
   echo "Exiting from $currentScript6"
   ((errorCode6 += 2))
   exit $errorCode6
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
   echo "Exiting from $currentScript6"
   ((errorCode6 += 3))
   exit $errorCode6
fi
slurmies=$(find ./bursts/lists/$burstDealingHere -maxdepth 1 -name "${SLURM_JOB_NAME}*.out" | wc -l)
if [ $slurmies -gt $maxSlurmies ]; then
   echo "Exiting because the maximum outputfiles have been reached: $slurmies>$maxSlurmies" 
   echo "Check in directory $PWD/bursts/lists/$burstDealingHere"
   echo "Exiting from $currentScript6"
   ((errorCode6 += 4))
   exit $errorCode6
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINING THE DELETE DECOMPOSED DIRECTORIES

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there is any decomposition
cd $workingDir
echo $PWD
if [ -d processor0 ]; then
   echo "Directory processor0 is here. Good! will attempt reconstruction."
else
   echo "Processor0 does not exists. Exiting"
   echo "Exiting from $currentScript6"
   ((errorCode6 += 5))
   exit $errorCode6
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Generating a list of existing time directories
function generateDirList(){
   currentDir=$PWD
   echo "Reading a list of existing time directories"
   cd $workingDir/processor0
   ls -dt [0-9]*/ | sed 's/\///g' > /tmp/listaDirsC.$SLURM_JOBID
   sort -rn /tmp/listaDirsC.$SLURM_JOBID -o /tmp/listaDirsOrdenadaC.$SLURM_JOBID
   i=0
   while read textTimeDir; do
      allTimeDirArr[$i]=$textTimeDir
      echo "The $i timeDir is: ${allTimeDirArr[$i]}"
      ((i++))
   done < /tmp/listaDirsOrdenadaC.$SLURM_JOBID
   allnTimeDirectories=$i
   if [ $allnTimeDirectories -eq 0 ]; then
      echo "Exiting because NO time directories available for the case"
      echo "Exiting from $currentScript6"
      ((errorCode6 += 6))
      exit $errorCode6
   else
      allMaxTimeSeen=${allTimeDirArr[0]}
      echo "The allMaxTimeSeen is $allMaxTimeSeen"
      if [ $allnTimeDirectories -lt $nAliveTimes ]; then
          jAlive=$(( i - 1 ))
      else
          jAlive=$(( nAliveTimes - 1 ))
      fi
      allAliveTimeSeen=${allTimeDirArr[$jAlive]}
      echo "The allAliveTimeSeen is $allAliveTimeSeen because nAliveTimes=$nAliveTimes are to be kept decomposed"
      echo "Times in that range will not be deleted"
   fi
   cd $currentDir
}
generateDirList

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Reading the list of times to delete
function readTimesToDelete(){
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
      echo "Exiting because NO time directories indicated for deleting"
      echo "Exiting from $currentScript6"
      ((errorCode6 += 7))
      exit $errorCode6
   else
      jIni=0
      minTimeInBurst=${timeDirArr[$jIni]}
      minTimeToDelete=$minTimeInBurst
      if float_cond "$minTimeToDelete == 0" || float_cond "$minTimeToDelete == $allStartTime"; then
         ((jIni += 1))
         minTimeToDelete=${timeDirArr[$jIni]}
      fi
      jEnd=$((nTimeDirectories - 1))
      maxTimeInBurst=${timeDirArr[$jEnd]}
      maxTimeToDelete=$maxTimeInBurst
      jEndAlive=$jEnd
      while float_cond "$maxTimeToDelete >= $allAliveTimeSeen"; do
         ((jEndAlive -= 1)) 
         maxTimeToDelete=${timeDirArr[$jEndAlive]}
         if [ $jEndAlive -eq -1 ]; then
            maxTimeToDelete=-1
            break
         fi
      done
      echo "The minTimeInBurst is $minTimeInBurst"
      echo "The maxTimeInBurst is $maxTimeInBurst"
      echo "The minTimeToDelete is $minTimeToDelete"
      echo "The maxTimeToDelete is $maxTimeToDelete"
   fi
}
readTimesToDelete
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#EXECUTING THE DELETING OF THE CURRENT BURST AND SENDING THIS SCRIPT RECURSIVELY 

#-----------------------------------------
#-----------------------------------------
#Cycle of checking for deleting decomposed times
deletedTimes=0 
shouldSleep="false" #Used as a flag to skip the first sleep after entering the cycle
dependantSent="false"
while ! [ -f $workingDir/bursts/lists/${burstDealingHere}/.fullyDeletedDecomposed ]; do
   echo "Starting deletion cycle"
   #-----------------------------------------
   #Sending the dependant job:
   cd $workingDir
   burstsDir=$workingDir/bursts/lists
   if [ "$dependantSent" == "false" ]; then
      echo "Sending a dependant job to keep the Deleting cycle of burst $burstDealingHere alive"
      next_jobid=$(sbatch --export="burstDealingHere=${burstDealingHere},performDeleteDecomposed=$performDeleteDecomposed,allStartTime=$allStartTime,nAliveTimes=$nAliveTimes,sleepTime=$sleepTime,previousMaxTimeSeen=$allMaxTimeSeen" --ntasks=$SLURM_NTASKS --job-name=$SLURM_JOB_NAME --output="$burstsDir/${burstDealingHere}/${SLURM_JOB_NAME}-%j.out" --dependency=afterany:${SLURM_JOB_ID} $dependantScript | awk '{print $4}')
      scontrol show job $next_jobid
      squeue -u $USER
      dependantSent="true"
   else
      echo "Dependant job was already sent before jobID=$next_jobid"
   fi
   echo "deletedTimes=$deletedTimes"
   echo "shouldSleep=$shouldSleep"
   if [ $deletedTimes -eq 0 ] && [ "$shouldSleep" == "true" ]; then 
      echo "Will sleep the deleting cycle for sleep=$sleepTime"
      echo "waiting for the run to create more times or the reconstruct and tarDecomposed procedures to finish before deletion"
      sleep $sleepTime
   fi
   echo "Checking the lists again"
   generateDirList
   readTimesToDelete
   deletedTimes=0 #Reseting the values for this iteration of the cycle
   shouldSleep="false"
   #deleting the desired directories
   echo "Deleting all times without the .deletedDecomposed file"
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if [ -f "./${jTime}/.deletedDecomposed" ]; then
          echo "Can't Delete ${jTime} as it was done already"
       elif ! [ -f "./${jTime}/.reconstructed" ]; then
          echo "NOT Deleting ${jTime} because it has not been reconstructed yet."
          shouldSleep="true"
       elif ! [ -f "./taredDecomposed/checks/${jTime}.taredDecomposed" ]; then
          echo "NOT Deleting ${jTime} because it has not been tared Decomposed yet."
          shouldSleep="true"
       elif (( $j > $jEndAlive )); then
           echo "Not Deleting ${jTime} because ${jTime} > maxTimeToDelete($maxTimeToDelete)"
           echo "Times larger than maxTimeToDelete are kept alive in this pass,"
           echo "but will be deleted in another job if the solution generates more time directories."
       else
          ((deletedTimes+=1))
          echo "YES Deleting ${jTime}"
          echo "Sending the deleting recursively in the background"
          Rlog=$workingDir/bursts/lists/${burstDealingHere}/DelDeco-${jTime}.log
          rm $Rlog
          srun --export="all,jTime=$jTime" -n 1 --mem-per-cpu=$SLURM_MEM_PER_CPU --exclusive --output=$Rlog $WorkFlowScriptsDir/singleDeleteDecomposed.sh &
       fi
   done
   wait
   #-----------------------------------------
   #-----------------------------------------
   #Checking if the burst deleting has been completed
   echo "Checking if the burst deleting has been completed"
   cd $workingDir
   fullyDeleted="true"
   for ((j=$jIni; j<=$jEnd; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if ! [ -f "./${jTime}/.deletedDecomposed" ]; then
          echo "Still ${jTime} in burst ${burstDealingHere} needs to be deletedDecomposed"
          fullyDeleted="false"
      fi
   done
   if [ $fullyDeleted == "true" ]; then
      echo "Decomposed times listed in $burstDealingHere have been deleted from:"
      echo " minTimeToDelete($minTimeToDelete) up to maxTimeInBurst($maxTimeInBurst)"
      touch "$burstsDir/${burstDealingHere}/.fullyDeletedDecomposed"
      if [ "$dependantSent" == "true" ]; then
         echo "Cancelling dependant job sent from here to keep the deleting cycle, jobId=$next_jobid"
         scancel $next_jobid 
      fi
      echo "Burst in $burstDealingHere has been fully deletedDecomposed"
      echo "The .fullDeletedDecomposed file has been generated"
      break
   fi
   #-----------------------------------------
   #-----------------------------------------
   #Checking if the burst deleting has been completed partially up to the limit of keep alive
   echo "Checking if the burst deleting has been completed up to the limit of keep alive times"
   cd $workingDir
   partiallyDeleted="true"
   for ((j=$jIni; j<=$jEndAlive; j+=1))
   do
       jTime=${timeDirArr[$j]}
       if ! [ -f "./${jTime}/.deletedDecomposed" ]; then
          echo "Still ${jTime} in burst ${burstDealingHere} needs to be deletedDecomposed"
          partiallyDeleted="false"
      fi
   done
   if [ $partiallyDeleted == "true" ]; then
      echo "Decomposed times listed in $burstDealingHere have been deleted from:"
      echo " minTimeToDelete($minTimeToDelete) up to maxTimeToDelete($maxTimeToDelete)"
      if float_cond "$previousMaxTimeSeen < $allMaxTimeSeen"; then
         echo "As maxTimeToDelete($maxTimeToDelete) < maxTimeInBurst($maxTimeInBurst), the dependant job will be kept alive"
      else
         echo "Even if maxTimeToDelete($maxTimeToDelete) < maxTimeInBurst($maxTimeInBurst), new times have not been generated"
         echo "previousMaxTimeSeen=$previousMaxTimeSeen"
         echo "allMaxTimeSeen=$allMaxTimeSeen"
         if [ "$dependantSent" == "true" ]; then
            echo "Cancelling dependant job, jobId=$next_jobid"
            scancel $next_jobid 
         fi
      fi
      echo "Burst in $burstDealingHere has been partially deletedDecomposed and this job will be stopped here."
      echo "But deletion still needs to go up to $maxTimeInBurst in a following pass if case creates more results"
      echo "No .fullDeletedDecomposed file will be generated"
      break
   fi
done


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP

echo "Delete Decomposed cycle script for burst list $burstDealingHere finished"
echo "Finishing $currentScript6"

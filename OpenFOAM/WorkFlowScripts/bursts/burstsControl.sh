#!/bin/bash
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This script is to update the controlDict dictionary before each burst
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript2=burstsControl.sh
echo "currentScript2=$currentScript2"
errorCode2=200

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#THE FOLLOWING VARIABLES NEED TO BE DEFINED IN THE MAIN SCRIPT WITH ADEQUATE VALUES
echo "-----------------------------------------------------------"
echo "Control variables were set in the main script:"
echo "allStartTime = ${allStartTime}"
echo "allEndTime = ${allEndTime}"
echo "deltaT = ${deltaT}"
echo "writeInterval = ${writeInterval}"
echo "burstRange = ${burstRange}"
echo "WorkFlowScriptsDir = ${WorkFlowScriptsDir}"
echo "workingDir = ${workingDir}"
echo "runStatus= ${runStatus}"
echo "-----------------------------------------------------------"
if [[ -z "$allStartTime" ]] ||
   [[ -z "$allEndTime" ]] ||
   [[ -z "$deltaT" ]] ||
   [[ -z "$writeInterval" ]] ||
   [[ -z "$burstRange" ]] ||
   [[ -z "$WorkFlowScriptsDir" ]] ||
   [[ -z "$workingDir" ]] ||
   [[ -z "$runStatus"  ]]; then
   echo "Some of the above variables were not defined correctly in the main script:"
   echo "Exiting from $currentScript2"
   echo "-----------------------------------------------------------"
   ((errorCode2 += 1))
   exit $errorCode2
fi



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINTION OF THE AUXILIARY FUNCTIONS
source $WorkFlowScriptsDir/defineAuxiliaryFunctions.sh


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINING THE NEW START AND END TIMES

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Generating a list of existing time directories
cd $workingDir
echo "PWD=$PWD"
echo "Reading a list of existing time directories" | tee -a ${logJob}
cd $workingDir/processor0
ls -dt [0-9]*/ | sed 's/\///g' > /tmp/listaDirs.$SLURM_JOB_ID
sort -rn /tmp/listaDirs.$SLURM_JOB_ID > /tmp/listaDirsOrdenada.$SLURM_JOB_ID
i=0
while read textTimeDir; do
   timeDirArr[$i]=$textTimeDir
#   echo "The $i timeDir is: ${timeDirArr[$i]}" | tee -a ${logJob}
   ((i++))
done < /tmp/listaDirsOrdenada.$SLURM_JOB_ID

nTimeDirectories=$i
if [ $nTimeDirectories -eq 0 ]; then
   echo "Exiting because NO time directories available" | tee -a ${logJob}
   echo "Exiting from $currentScript2"
   ((errorCode2 += 2))
   exit $errorCode2
else
   maxTimeSeen=${timeDirArr[0]}
   echo "The maxTimeSeen is $maxTimeSeen" | tee -a ${logJob}
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Defining the time from which to restart
if [ $nTimeDirectories -eq 1 ]; then
   startTime=${timeDirArr[0]}
   echo "Using the only existing time: $startTime for restart: modifying controlDict" | tee -a ${logJob}
else
   echo "The last timeDir is: ${timeDirArr[0]}" | tee -a ${logJob}
   echo "The secondLast timeDir is: ${timeDirArr[1]}" | tee -a ${logJob}
   startTime=${timeDirArr[1]}
   echo "Using the secondLast time: $startTime for restart: modifying controlDict" | tee -a ${logJob}
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#If there is a forced restart time, force it once:
echo "forcedStartTime=$forcedStartTime"
if [[ -z "$forcedStartTime" ]] || [[ $forcedStartTime -lt 0 ]]; then
   echo "Not using a forced restart time as it is null or negative"
else
   startTime=$forcedStartTime
   forcedStartTime=-1
   echo "Using forced restart time ONLY ONCE as it is set to a positive value"
fi


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Defining the endTime together with the controlDict setup
cd $workingDir
echo "PWD=$PWD"

! [ -d ./system/previousTo ] && mkdir -p ./system/previousTo
! [ -d ./system/usedIn ] && mkdir -p ./system/usedIn

if float_cond "$startTime < $allEndTime"; then
   endTime=$(float_eval "$startTime + $burstRange")
   #Setting up the controlDict
   cp ./system/controlDict ./system/previousTo/controlDict.previousTo.$SLURM_JOBID
   cp ./system/controlDict.template ./system/controlDict
   replaceFirstFoamParameter startFrom startTime ./system/controlDict
   replaceFirstFoamParameter startTime $startTime ./system/controlDict
   replaceFirstFoamParameter stopAt endTime ./system/controlDict
   replaceFirstFoamParameter endTime $endTime ./system/controlDict
   replaceFirstFoamParameter deltaT $deltaT ./system/controlDict
   replaceFirstFoamParameter writeInterval $writeInterval ./system/controlDict
   cp ./system/controlDict ./system/usedIn/controlDict.usedIn.$SLURM_JOBID
else
   echo "Case is finished. startTime($startTime) >= allEndTime($allEndTime)"
   export runStatus="done"
   echo "Setting runStatus=$runStatus"
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP
echo "Finishing $currentScript2"

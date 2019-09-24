#/bin/bash
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#In this script we identify runTimeErrors so that the cycle can be stopped
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript9=checkRunErrors.sh
echo "currentScripts9=$currentScript9"
errorCode9=900

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#All this work for the variable currentLogFile

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Basic checks
if ! [ -d logs ]; then
   echo "The ./logs directory does not exist"
   echo "Exiting from $currentScript9"
   ((errorCode9 += 1))
   exit $errorCode9
fi
if ! [ -f $currentLogFile ]; then
   echo "The currentLogFile does not exist"
   echo "Exiting from $currentScript9"
   ((errorCode9 += 2))
   exit $errorCode9
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Checking that the last line has the successfull message
correctPhrase="Finalising"
correctEnd=$(tail -n 10 $currentLogFile | grep $correctPhrase | wc -l)
if (( $correctEnd == 1 )); then
   echo "Successful execution of OpenFOAM solver"
   echo "As seen in $currentLogFile"
else
   echo "Error in the OpenFOAM solver"
   echo "As seen in $currentLogFile"
   ((errorCode9 += 3))
   exit $errorCode9 
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Checking that the last line has the successfull message
incorrectPhrase="ERROR"
incorrectEnd=$(tail -n 100 $currentLogFile | grep-i $incorrectPhrase | wc -l)
if (( $incorrectEnd == 0 )); then
   echo "No ERRORs found in the log file of OpenFOAM solver"
   echo "As seen in $currentLogFile"
else
   echo "$incorrectPhrase word found in the log file of the OpenFOAM solver"
   echo "As seen in $currentLogFile"
   ((errorCode9 += 4))
   exit $errorCode9 
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP
echo "Finishing $currentScripts9"

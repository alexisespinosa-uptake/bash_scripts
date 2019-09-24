#/bin/bash
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#In this script we define the different auxiliary functions to be used
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
currentScript1=defineAuxiliaryFunctions.sh
echo "currentScript1=$currentScript1"
errorCode1=100

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#DEFINTION OF THE AUXILIARY FUNCTIONS

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Directory of the definition of auxiliary functions
#functionsD=$HOME/bash_functions
functionsD=$MYGROUP/bash_scripts/bash_functions

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Sourcing the floating point function defininitons
#Global variable to be used as scale=$float_scale in bc floatingPoint functions
float_scale=4
archi=$functionsD/floatingPoint.sh
if [ -e $archi ]; then
   echo "Found floatingPoint functions" | tee -a ${logJob}
   source $archi
else
   echo "NOT FOUND floatingPoint functions" | tee -a ${logJob}
   echo "Exiting from $currentScript1"
   ((errorCode1 += 1))
   exit $errorCode1
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Sourcing the auxiliary function defininitons
archi=$functionsD/auxiliaryFunctions.sh
if [ -e $archi ]; then
   echo "Found auxiliary functions" | tee -a ${logJob}
   source $archi
else
   echo "NOT FOUND auxiliary functions" | tee -a ${logJob}
   echo "Exiting from $currentScript1"
   ((errorCode1 += 2))
   exit $errorCode1
fi

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#FINAL STEP
echo "Finishing $currentScript1"

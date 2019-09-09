#!/bin/bash
date
auxout=/tmp/Recons-${jTime}.auxout
echo "Auxiliary output file is $auxout"
reconstructPar -time "${jTime}" -fileHandler uncollated 2>&1 | tee $auxout
#Searching keywords that tell something went wrong. If nothing went wrong add the .reconstructed file to the time dir
if grep -i 'error\|exiting' $auxout; then
   echo "The reconstruction of time ${jTime} has failed."
else
   touch "./${jTime}/.reconstructed"
   if [ -f "./${jTime}/.reconstructed" ]; then
      echo  "Time ${jTime} has been reconstructed and the \".reconstructed\" file added to the \"${jTime}\" dir." 
   fi
fi
date

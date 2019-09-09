#!/bin/bash
date
auxout=/tmp/TarDeco-${jTime}.auxout
echo "Auxiliary output file is $auxout"
echo "Deleting files within processor*/${jTime}"
find -P . -mindepth 2 -maxdepth 2 -type d -name "${jTime}" -print0 | xargs -0 -I{} find -P {} -type f -print0 -o -type l -print0 | xargs -0 munlink
echo "Deleting directory processor*/${jTime}"
find -P . -mindepth 2 -maxdepth 2 -type d -name "${jTime}" -print0 | xargs -0 -I{} find {} -depth -type d -empty -delete
#Check if there are still files to delete
leftovers=$(find -P . -mindepth 2 -maxdepth 2 -type d -name "${jTime}" | wc -l)
echo "leftovers = $leftovers"
if [ $leftovers -gt 0 ]; then
   echo "The Delete Decomposed of time ${jTime} has failed."
   echo "There are $leftovers leftover directories"
   find -P . -mindepth 2 -maxdepth 2 -type d -name "${jTime}"
else
   touch "./${jTime}/.deletedDecomposed"
   if [ -f "./${jTime}/.deletedDecomposed" ]; then
      echo  "Time ${jTime} has been Deleted Decomposed and the \".deletedDecomposed\" file added to the \"${jTime}\" dir." 
   fi
fi
date

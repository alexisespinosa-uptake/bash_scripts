#!/bin/bash
date
status1=0
status2=0
find -P . -mindepth 2 -maxdepth 2 -type d -name "${jTime}" -print0 | tar -cvf ./taredDecomposed/${jTime}.tar --null -T -
status1=${PIPESTATUS[1]}
tar -xvf ./taredDecomposed/${jTime}.tar -O > /dev/null
status2=$?
if [ $status1 -ne 0 ] && [ $status2 -ne 0 ]; then
   echo "The TaringDecomposed of time ${jTime} has failed."
   echo "status1=$status1"
   echo "status2=$status2"
else
   ! [ -d ./taredDecomposed/checks ] && mkdir -p ./taredDecomposed/checks
   touch "./taredDecomposed/checks/${jTime}.taredDecomposed"
   if [ -f "./taredDecomposed/checks/${jTime}.taredDecomposed" ]; then
      echo  "Time ${jTime} has been taredDecomposed and the \"${jTime}.taredDecomposed\" file added to the \"./taredDecomposed/checks\" dir." 
   fi
fi
date

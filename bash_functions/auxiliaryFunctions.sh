#!/bin/bash -l
#
# Some funtions useful for some of my scripts
#
# Alexis Espinosa

################################################################
# Function to copy files
copyFile () {
   if [ $# != 2 ]; then
      echo "Exiting function "copyFile" because the number of arguments is not 2. Nargs=$#:" | tee -a ${logJob}
      echo "Usage: copyFile fileOrigin fileDestin" | tee -a ${logJob}
      exit 2
   fi
   fileOrigin=$1
   fileDestin=$2
   if [ -f "${fileOrigin}" ]; then
      cp $fileOrigin $fileDestin
   else
      echo "Exiting function "copyFile" because Original file does not exist:" | tee -a ${logJob}
      echo "${fileOrigin}" | tee -a ${logJob}
      exit 3
   fi
   return 0
}


################################################################
# Function for replacing the existing definition of a parameter that is defined in the first column
replaceFirstFoamParameter () {
   if [ $# != 3 ]; then
      echo "Exiting function "replace_first" because the number of arguments is not 3.Nargs=$#:"
      echo "Usage: replaceFirst parameter value file"
      exit 1
   fi
   parameter=$1
   value=$2
   file=$3
   echo "Replacing ${file} parameter ${parameter} into -> ${value}"
   sed -i -e '/^'"${parameter}"'.*/a'"${parameter}"'    '"${value}"';' ${file}
   sed -i -e '0,/^'"${parameter}"'/s//\/\/ '"${parameter}"'/' ${file}
}

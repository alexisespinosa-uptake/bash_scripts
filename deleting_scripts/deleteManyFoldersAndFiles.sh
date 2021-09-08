#!/bin/bash

#------------------------------------------
#-------------------------------------------
# Initial settings and variables
thisScript=`basename "$0"`
echo " "

#------------------------------------------
#-------------------------------------------
#Usage explanation function
usage()
{
    echo "---------------------------------------------------------"
    echo "  ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR  "
    echo "---------------------------------------------------------"
    echo "The deleting script has detected no arguments, which is not right."
    echo "For this script, arguments are considered as the directories (or specific files) to be"
    echo "deleted completely, so no arguments makes no sense."
    echo "The \"second\" type of argument is by using: \"--list <fileContainingList>\","
    echo "where \"fileContainingList\" is a text file where each line is the path to the directory (or file)"
    echo "to be deleted completely."
    echo ""
    echo "For example:"
    echo "${thisScript} myDir1 myDir2 --list listInFile.txt"
    echo ""
    echo "Exiting this job request .."
    exit 1
} 


#------------------------------------------
#-------------------------------------------
#Reading the arguments to define the directories to be deleted
declare -a delDirArr=()
unset fileWithList
if [ "$#" -eq 0 ]; then
   usage
else
   while [[ $# -gt 0 ]]; do       # while the number of arguments is greater than 0 (shifts will advance the list)
      key="$1"
      case $key in
         "--list")                      # a file with the list of directories/files to be deleted was given
            fileWithList="$2"      
            shift
            shift
            ;;
         "--List")                      # a file with the list of directories/files to be deleted was given
            fileWithList="$2"      
            shift
            shift
            ;;
         "--LIST")                      # a file with the list of directories/files to be deleted was given
            fileWithList="$2"      
            shift
            shift
            ;;
         *)
            delDirArr+=("$1")       # a given file/directory to delete
            shift
            ;;
      esac
   done
fi
#Reading the file with the list of directories to be deleted
if [ ! -z "$fileWithList" ]; then
   if [ -f "$fileWithList" ]; then
      while read nextLine; do
         delDirArr+=("$nextLine")
      done < $fileWithList
   else
      echo "The file that has the list (given with argument \"-f $fileWithList\") does not exist"
      exit 2
   fi
fi
NDirs=${#delDirArr[@]}
echo "There are $NDirs directories listed to delete"
for iDir in "${delDirArr[@]}"; do
   echo "$iDir"
done


#-------------------------------------------
#-------------------------------------------
#Echoing the slurm settings that this script has received from a calling script:
echo " "
echo "Echoing slurm settings from the calling script:"
echo "SLURM_JOB_NAME=${SLURM_JOB_NAME}"
echo "SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "SLURM_SUBMIT_DIR=${SLURM_SUBMIT_DIR}"
echo "SLURM_JOB_NUM_NODES=${SLURM_JOB_NUM_NODES}"
echo "SLURM_NTASKS=${SLURM_NTASKS}"
echo "SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"

#-------------------------------------------
#-------------------------------------------
#These variables should come from the calling script, if not defined then here are defined defaults
echo " "
#....
baseDirectory=$SLURM_SUBMIT_DIR
baseDirectory="${baseDirectory:-$PWD}"
echo "The base directory to be used is: ${baseDirectory}"
#....
baseFileName=$SLURM_JOB_NAME
baseFileName="${baseFileName:-DMF}"
echo "The base base name for the auxilary files to be created is: ${baseFileName}"
#....
#useDependantCycle Should be defined in the calling script, if not this is default:
useDependantCycle="${useDependantCycle:-false}"
echo "Set-up for the dependant cycle is useDependantCycle=${useDependantCycle}"
#....
#dependantScript Should be defined in the calling script, if not this is default:
dependantScript="${dependantScript:-None.slm}"
echo "Set-up name for the script to be sent next iteration of the cycle is dependantScript=${dependantScript}"
#....
#maxIterations Should be defined in the calling script, if not this is default:
maxIterations="${maxIterations:-10}"
echo "Set-up for the maximum number of dependant iterations to be performed in the cycle is maxIterations=${maxIterations}"
#....
#currentIteration Is identified in the main calling program, if not this is default:
currentIteration="${currentIteration:-$maxIterations}"
echo "Set-up for the current iteration being performed in this cycle is currentIteration=${currentIteration}"
#....
nextIteration=$(( $currentIteration + 1 ))
echo "And nextIteration=${nextIteration}"

#-------------------------------------------
#-------------------------------------------
#Defining some other specific parameters for this script
#....

#------------------------------------------
#-------------------------------------------
#Defining functions
recursiveDeletion() {
   local dirToDelete=$1

   # Check if empty
   if [ -z "$dirToDelete" ]; then
      return 0
   fi

   if [ ! -z "${OUTPUT}" ]; then
      echo "Traversing directory $dirToDelete"
   fi

   #Process children
   for childDir in $(find -H $dirToDelete -mindepth 1 -maxdepth 1 -type d -print); do
      recursiveDeletion "$childDir"
   done

   if [ ! -z "${OUTPUT}" ]; then
      echo "Processing directory $dirToDelete"
   fi

   #Process this directory
   if [ ! -z "${DRYRUN}" ]; then
      find -H $dirToDelete -mindepth 1 -maxdepth 1 -type f -o -type l -exec echo " Deleting file {}" \;
      find -H $dirToDelete -mindepth 1 -maxdepth 1 -type d -empty -exec echo " Deleting dir {}" \;
   else
      find -H $dirToDelete -mindepth 1 -maxdepth 1 -print0 -type f -o -type l | xargs -0 munlink
      find -H $dirToDelete -mindepth 1 -maxdepth 1 -type d -empty -delete
      rmdir $dirToDelete 
   fi
}

echoWarning() {
    echo "---------------------------------------------------------"
    echo " WARNING WARNING WARNING WARNING WARNING WARNING WARNING "
    echo "---------------------------------------------------------"
}

echoError() {
    echo "---------------------------------------------------------"
    echo "  ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR  "
    echo "---------------------------------------------------------"
}
echoImportant() {
    echo "IMPORTANT:"
    echo "The problem may be that you need to use a different --job-name for this slurm script."
    echo "Remeber that each job should have its unique --job-name in order to avoid confussion in the cycles"
    echo "of resubmission."
    echo "In short, use different --job-name if you are using different slurm scripts for deleting a different"
    echo "set of directories."
    echo ""
    echo "If for any reason you want to cancel the jobs that are running,"
    echo "remember to scancel the pending jobs with Dependency FIRST."
    echo "Then you can proceed to scancel the running jobs."
}

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Changing to the base directory
echo " "
cd $baseDirectory
echo "Working from the baseDirectory: ${baseDirectory}"
echo "All auxiliary files will be created there"


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Avoiding falling into an infinite loop of calling job scripts with recurrent errors
#which generate huge amount of files
if [ $currentIteration -gt $maxIterations ]; then
    echoError
    echo "Exiting because the maximum number of iterations (resending of the slurm script) has been reached:"
    echo "currentIteration=$currentIteration > $maxIterations"
    echo "If your deletion process is not finished yet, please read your latests log files."
    echo "and check if there is any particular issue/error that is causing your process to take"
    echo "too long to finish:"
    ls ${baseFileName}*
    echo "If everything is fine, you can resubmit the slurm script again."
    echo "Depending on the amount of work that still needs to be done,"
    echo "you may want to consider to increase the maxIterations"
    echo "variable inside the slurm script"
    echo "Exiting this job request .."
    exit 2
fi

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# Identifying if is there another job with the same name already running
echo " "
echo "Identifying if there is another job with the same name already running"
squeue -u $USER --name="$SLURM_JOB_NAME"
nRunning=$(squeue -u $USER --name="$SLURM_JOB_NAME" --state=RUNNING | wc -l)
nRunning=$(($nRunning - 2))

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking if there are other pending jobs with the same name
echo " "
echo "Checking if there are other pending jobs with the same name"
nPending=$(squeue -u $USER --name="$SLURM_JOB_NAME" --state=PENDING | wc -l)
nPending=$(($nPending - 1))

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Checking logic for cancelling existing running and pending jobs and resubmitting
echo " "
echo "Checking logic for cancelling existing running and pending jobs and resubmitting"
if [ $nRunning -ge 2 ] || [ $nPending -ge 2 ]; then
    echoError
    echo " "
    echo "The name of this job is: ${SLURM_JOB_NAME}"
    echo "TWO OR MORE jobs with the same name are already running. SameNames=${nRunning}" 
    echo "or TWO OR MORE jobs with the same name are already pending. Pending=${nPending}"
    echo "This job will stop and the user should check the status of the existing jobs in the cue"
    echo "with the command: squeue"
    echoImportant
    echo "Exiting this job request .."
    exit 3
elif [ $nRunning -eq 1 ] && [ $nPending -le 1 ]; then
    echoError
    echo " "
    echo "The name of this job is: ${SLURM_JOB_NAME}"
    echo "ONE job with the same name is already running. SameNames=${nRunning}"
    echo "And one or none jobs with the same name are already pending. Pending=${nPending}"
    echo "Everything looks fine in the queue for that running job and dependants."
    echo "So That job will be left running"
    echo "But this job request will be cancelled, as two jobs with the same --job-name will confund the"
    echo "resubmission process."
    echoImportant
    echo "Exiting this job request .."
    exit 4
elif [ $nRunning -eq 0 ] && [ $nPending -eq 1 ]; then
    echoError
    echo " "
    echo "The name of this job is: ${SLURM_JOB_NAME}"
    echo "There was a single orphan pending job with the same name. SameNames=${nRunning}, Pending=${nPending}"
    echo "The pending job will be left it in the queue And This job request will be cancelled"
    echoImportant
    echo "Exiting this job request .."
    exit 5
else
    echo " "
    echo "The name of this job is: ${SLURM_JOB_NAME}"
    echo "No SameName-Jobs already running exist. Good! SameNames=${nRunning}, Pending=${nPending}"
    echo "Now, This job will be proceed to submit a dependant job and to proceed to deletion"
fi


#-------------------------------------------
#-------------------------------------------
#Resubmitting a dependant script which will continue the deleting process after the calling script reaches
#the walltime or is killed/stopped unexpectedly
echo " "
if [ "$useDependantCycle" = "true" ]; then
    echo "Sending also the dependant job: ${dependantScript}"
    sonJobID=$(sbatch --export=currentIteration=${nextIteration} --parsable --dependency=afterany:${SLURM_JOB_ID} ${dependantScript})
    sonJobID=${sonJobID%";zeus"}
    echo "The dependant script has sonJobID=${sonJobID}"
else
    echo "useDependantCycle=false, therefore NOT SENDING the dependant script" 
fi


#-------------------------------------------
#-------------------------------------------
#Cycle along the list of directories defined within delDirArr
echo " "
echo "Cycle along the list of directories defined within delDirArr"
nothingDone=true
echo "Nothing has been done yet. We are starting. Setting the flag nothingDone=${nothingDone}"
echo "Counting how many files are in the system:"
lfs quota -hu $USER /scratch
lfs quota -hu $USER /group
for i in `seq 0 $((NDirs-1))`; do
    #Defining the folder to delete:
    echo "Processing directory of index i=${i}"
    echo "The directory to delete is: ${delDirArr[$i]}"
    delDir=${delDirArr[$i]}
    #Checking if the delDir variable is properly set
    if [ -z "$delDir" ] && [ "${delDir+xxx}" = "xxx" ]; then
        echoWarning
        echo "The variable delDir is set but empty"
        echo "Directory to delete: delDir=${delDir}"
        echo "This could be dangerous, so please check your input list"
        echo "Possibly, one of your lines in the list is a blank line."
        echo "Doing nothing with that entry and moving to the next element of the list"
        echo ".continue."
        echo " ---------------------------"
        echo ""
        continue
    fi
    #Checking if the delDir variable is properly set
    if echo x"$delDir" | grep -q '*'; then
        echoWarning
        echo "The variable delDir has the wildcard character *"
        echo "This could be dangerous, so please only use full names in your directories names,"
        echo "and resubmit your deletion job."
        echo "Doing nothing with that entry and moving to the next element of the list"
        echo ".continue."
        echo " ---------------------------"
        echo ""
        continue
    fi
    #Proceding to delete the directory/ies indicated
    if [ -d $delDir ]; then 
        #-------------------------------------------
        echo "Starting the process for deleting directory: ${delDir}"
        echo "Counting how many files are in the system at this point in time:"
        lfs quota -hu $USER /scratch
        lfs quota -hu $USER /group
        if [ "$nothingDone" = "true" ]; then
           nothingDone=false
           echo "Setting nothingDone=${nothingDone}"
        fi

        #-------------------------------------------
        #Main deletion operation
        recursiveDeletion $delDir

        #-------------------------------------------
        #Checking for the finished deletion and end of the cycle
        if ! [ -d $delDir ]; then
           echo "Deletion of the directory is finished: ${delDir}"

        else
           echo "Deletion of this directory faced some issues and has not been fully removed: ${delDir}"
        fi
    elif [ -f $delDir ]; then
        echo "${delDir} is a file. Deleting it"
        rm $delDir
        if [ "$nothingDone" = "true" ]; then
           nothingDone=false
           echo "Setting nothingDone=${nothingDone}"
        fi
    else
        echoWarning
        echo "${delDir} does not exists"
        echo " ---------------------------"
        echo ""
    fi
done

#-------------------------------------------
#-------------------------------------------
#Cancelling dependant job if nothing was done
if [ "$nothingDone" = "true" ]; then
    echo ""
    echoWarning
    echo "Nothing was done really during the script. The flag is nothingDone=${nothingDone}."
    echo "Cancelling the dependant job:${sonJobID}"
    scancel ${sonJobID}
    echo "Setting the current iteration to an out of range number in order to stop resubmission"
    currentIteration=$(( $maxIterations + 1 ))
    echo "currentIteration=${currentIteration}"
    echo "And the script will not be resubmitted again"
    echo " ---------------------------"
    echo ""
fi

#-------------------------------------------
#-------------------------------------------
#Final lines
echo " "
echo "The script has reached the end, exiting with success"
echo "Counting how many files are in the system:"
lfs quota -hu $USER /scratch
lfs quota -hu $USER /group
exit 0

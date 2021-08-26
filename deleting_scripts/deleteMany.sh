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
    echo "The deleting script has detected ${#} arguments, which is not right."
    echo "This script accepts only one argument, which is either the name of a directory, like"
    echo "Single directory example: ${thisScript} nameOfDirectoryToDelete"
    echo ""
    echo "Or the name of a text file which contains a list of directories in each line, like"
    echo "Using a list example: ${thisScript} nameOfFileWithTheList.txt"
    echo ""
    echo "IMPORTANT: Usually this script is executed within a SLURM jobscript sent to the copyq"
    echo "           For an example of the typical jobscript, please check Pawsey Documentation"
    echo "           within the \"Knowledge Base\" section"
    echo "Exiting this job request .."
    exit 1
} 


#------------------------------------------
#-------------------------------------------
#Reading the arguments with the directory or the directories' list to delete
DIRS=()
delDirArr=[]
if [ "$#" -eq 0 ]; then
   usage
else
   while [[ $# -gt 0 ]]; do            # while the number of arguments is greater than 0
      key="$1"
      case $key in
         -d)
            dest="$(readlink -f $2)"      # determine the full path of the destination
            shift
            shift
            ;;
         *)
            DIRS+=("$1")           # capture arguments not connected to options in an array
            shift
            ;;
      esac
   done
   #set -- "${DIRS[@]}"            # restore the non-option args to command line args 
fi

#------------------------------------------
#-------------------------------------------
#Reviewing what will be performed:
echo "In 0:"
echo "${DIRS[@]}"
set -- "${DIRS[@]}"            # restore the non-option args to command line args 
echo "In 1:"
echo "${DIRS[@]}"
exit


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
echo "SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"

#-------------------------------------------
#-------------------------------------------
#These variables should come from the calling script, if not defined then here are defined defaults
echo " "
#....
nCores=$SLURM_JOB_CPUS_PER_NODE
nCores="${nCores:-10}"
echo "The number of cores to be used is: ${nCores}"
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
# Number of files/directories to be processed by munlink and rmdir at a time
# This argument may need additional tweaking for obtaining optimal performance
nFilesPerCore=100
echo "The number of lines to be chunked for xargs is -L${nFilesPerCore}"
#....
# Minumum Number of files expected to be found "quick" in order to proceed directly to munlink or rmdir cycles
rmLimit=100
#....
# Waiting time in seconds for the "quick" find
limitQuickFindTest=30
echo "For the quick check for files, will look for ${rmLimit} files in ${limitQuickFindTest} seconds."
#....
# Waiting time in minutes for trying to delete files or directories (currently not in use, but was used in previous versions)
#limitDeleteTime=15
#echo "For deleting files the cycles will be ${limitDeleteTime} minutes long each try"
#....
# Waiting time in minutes for trying to delete "nasty" files or directories that only go away with rm -rf
limitDeleteRMRF=2
echo "For deleting nasty files the cycles will be ${limitDeleteRMRF} minutes long each try"
#....
# Maximum number of external overall deleting cycles (around 200 cycles of 15 minutes in 48 hours)
NMaxCycles=200
echo "For deleting files the maximum number of cycles will be ${NMaxCycles}"
#....
# Maximum number of small internal deleting mini-cycles
NMaxInternalCycles=120
echo "For deleting files the maximum number of small internal mini-cycles will be ${NMaxInternalCycles}"
#....
# Waiting time in seconds for trying to delete files or directories during each internal mini-cycle
limitInternalDeleteTime=30
echo "For deleting files the Internal Cycles will be ${limitInternalDeleteTime} seconds long each try"
#....
# Number of parallel executions of munlink or rmdir within the xargs call
# This parameter needs to be tunned. But from my tests, a value of 2 is very good
# In the future will be related to NCores, but for now its fixed:
nPXargs=2
echo "Parallel processing in xargs will be done with -P${nPXargs}"
echo "Checking Xargs parallel effectivity"
echo "with:  seq 10 | xargs -n 1 -P10  sleep"
time seq 10 | xargs -n 1 -P10 sleep

#------------------------------------------
#-------------------------------------------
#Defining functions
munlinkFilesAndLinks() {
    for (( internalCycles=0; internalCycles<$NMaxInternalCycles; internalCycles++ )); do
        echo "First deleting the auxiliary file from previous mini-cycle: /tmp/${baseDelDir}.${baseFileName}.toDelete"
        rm /tmp/${baseDelDir}.${baseFileName}.toDelete
        echo "Internal mini-cycle=${internalCycles} for deleting files within directory: ${delDirArr[$i]}"
        echo "Counting files to delete:"
        timeout ${limitInternalDeleteTime}s find -P ${delDir} -type f -print0 -o -type l -print0 | xargs -0 -I "{}" echo "'{}'" >> /tmp/${baseDelDir}.${baseFileName}.toDelete
        nToDelete=$(sed -n '$=' /tmp/${baseDelDir}.${baseFileName}.toDelete)
        nToDelete="${nToDelete:-0}"
        echo "Find got $nToDelete files to delete within directory in the internal cycle in ${limitInternalDeleteTime} seconds."
        if [ $nToDelete -eq 0 ]; then
            internalCycles=$NMaxInternalCycles
            echo "Nothing found to delete"
            echo "Exiting the internal cycle"
        elif [ $nToDelete -eq 1 ]; then
            sed ';' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} munlink
            internalCycles=$NMaxInternalCycles
            echo "Files found were deleted."
            echo "Exiting the internal cycle"
        elif [ $nToDelete -lt $rmLimit ]; then
            sed ';$d' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} munlink
            internalCycles=$NMaxInternalCycles
            echo "Files found were deleted."
            echo "Less than $rmLimit, exiting the internal cycle"
        else
            sed ';$d' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} munlink
            echo "Files found were deleted."
            echo "Continuing the internal cycle"
        fi
    done
}

deleteEmptyDirs() {
    for (( internalCycles=0; internalCycles<$NMaxInternalCycles; internalCycles++ )); do
        echo "First deleting the auxiliary file from previous mini-cycle: /tmp/${baseDelDir}.${baseFileName}.toDelete"
        rm /tmp/${baseDelDir}.${baseFileName}.toDelete
        echo "Internal mini-cycle=${internalCycles} for deleting empty subdirectories within directory: ${delDirArr[$i]}"
        echo "Counting empty directories:"
        timeout ${limitInternalDeleteTime}s find -P ${delDir} -mindepth 1 -type d -empty -print0 | xargs -0 -I "{}" echo "'{}'" >> /tmp/${baseDelDir}.${baseFileName}.toDelete
        nToDelete=$(sed -n '$=' /tmp/${baseDelDir}.${baseFileName}.toDelete)
        nToDelete="${nToDelete:-0}"
        echo "Find got $nToDelete empty directories to delete in the internal cycle in ${limitInternalDeleteTime} seconds."
        if [ $nToDelete -eq 0 ]; then
            internalCycles=$NMaxInternalCycles
            echo "Nothing found to delete"
            echo "Exiting the internal cycle"
        elif [ $nToDelete -eq 1 ]; then
            sed ';' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} rmdir
            internalCycles=$NMaxInternalCycles
            echo "Empty directories found were deleted."
            echo "Exiting the internal cycle"
        elif [ $nToDelete -lt $rmLimit ]; then
            sed ';$d' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} rmdir
            internalCycles=$NMaxInternalCycles
            echo "Empty directories found were deleted."
            echo "Less than $rmLimit, exiting the internal cycle"
        else
            sed ';$d' /tmp/${baseDelDir}.${baseFileName}.toDelete | xargs -L${nFilesPerCore} -P ${nPXargs} rmdir
            echo "Empty directories found were deleted."
            echo "Continuing the internal cycle"
        fi
    done
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
    echo "If everythin is fine, you can resubmit the slurm script again."
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
echo " "
#Checking if there are other pending jobs with the same name
nPending=$(squeue -u $USER --name="$SLURM_JOB_NAME" --state=PENDING | wc -l)
nPending=$(($nPending - 1))

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
#Logic for cancelling existing running and pending jobs and resubmitting
echo " "
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
#Defining the list of directories to delete within the "delDirArr" array
echo " "
i=0
if [ -d "$argument" ]; then
    echo "The argument:${argument}, is a directory"
    delDirArr[$i]=$argument
    ((i++))
elif [ -d "./$argument" ]; then
    echo "The argument:./${argument}, is a directory"
    delDirArr[$i]=./$argument
    ((i++))
elif [ -f "$argument" ]; then
    echo "The argument:${argument}, is a file with a list"
    while read readLine
    do
        delDirArr[$i]=$readLine
        ((i++))
    done < $argument
elif [ -f "./$argument" ]; then
    echo "The argument:./${argument}, is a file with a list"
    while read readLine
    do
        delDirArr[$i]=$readLine
        ((i++))
    done < ./$argument
else
    echoError
    echo "The argument given to the script:${argument},"
    echo "is not a directory nor a file containing a list of directories to be deleted"
    echo "Exiting this job request .."
    exit 6
fi
NDirs=$(($i - 1))

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
#Removing leftovers of auxiliary files generated by this script from a previous iteration of job-submissions
echo " "
echo "Removing rmLimit files from previous submissions"
ls /tmp/*.${baseFileName}.rmLimit
rm /tmp/*.${baseFileName}.rmLimit
echo " "
echo "Removing toDelete files from previous submissions"
ls /tmp/*.${baseFileName}.toDelete
rm /tmp/*.${baseFileName}.toDelete


#-------------------------------------------
#-------------------------------------------
#Cycle along the list of directories defined within delDirArr
echo " "
nothingDone=true
echo "Nothing has been done yet. We are starting. Setting the flag nothingDone=${nothingDone}"
echo "Counting how many files are in the system:"
lfs quota -hu $USER /scratch
lfs quota -hu $USER /group
for i in `seq 0 ${NDirs}`; do
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
        #Main overall cycle of deletion
        for (( cycles=0; cycles<$NMaxCycles; cycles++ )); do
            echo "Overall main cycle=${cycles} for deleting directory: ${delDirArr[$i]}"
            echo "Counting how many files are in the system:"
            lfs quota -hu $USER /scratch
            lfs quota -hu $USER /group
            nothingDone=false
            echo "Setting nothingDone=${nothingDone}"
            nFiles=0
            nEmpties=0
            baseDelDir=`basename "${delDir}"`
            #-------------------------------------------
            #Checking for the existence of files
            echo "1.0 Finding for at least ${rmLimit} files within ${limitQuickFindTest} seconds"
            timeout ${limitQuickFindTest}s find -P ${delDir} -type f -o -type l | head -${rmLimit} > /tmp/${baseDelDir}.${baseFileName}.rmLimit 
            nFiles=$(sed -n '$=' /tmp/${baseDelDir}.${baseFileName}.rmLimit)
            nFiles="${nFiles:-0}"
            echo "1.1 In ${limitQuickFindTest} seconds, find saw ${nFiles} files in the tree ${delDir}."
            rm /tmp/${baseDelDir}.${baseFileName}.rmLimit
            #Deleting files:
            if [ $nFiles -gt 0 ]; then
                echo "Deleting existing files until we do not find files easily anymore"
                echo "1.2 So it will starting with munlink"
                #echo "Trying for ${limitDeleteTime} minutes"
                echo "Date starting:"
                date
                #AEG:NotUsingNow:find -P ${delDir} -type f -o -type l -print0 | xargs -0 -P ${nPXargs} munlink
                #AEG:1stIdea:LastGoodOne:timeout ${limitDeleteTime}m find -P ${delDir} -type f -o -type l -print0 | xargs -0 -L${nFilesPerCore} -P ${nPXargs} munlink
                #AEG:2ndIdea:time find -P ${delDir} -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -L1 -P${nPXargs} --replace=@ find -P @ -type f -o -type l -print0 | xargs -0 -L${nFilesPerCore} -P ${nPXargs} munlink
                #AEG:3rdIdea:Calling the function:
                munlinkFilesAndLinks
                echo "Date finishing:"
                date
            fi

            #-------------------------------------------
            #Checking for the existence of empty dirs
            echo "2.0 Finding for at least ${rmLimit} empty dirs within ${limitQuickFindTest} seconds"
            timeout ${limitQuickFindTest}s find -P ${delDir} -mindepth 1 -depth -type d -empty | head -${rmLimit} > /tmp/emptyDirs.${baseDelDir}.${baseFileName}.rmLimit 
            nEmpties=$(sed -n '$=' /tmp/emptyDirs.${baseDelDir}.${baseFileName}.rmLimit)
            nEmpties="${nEmpties:-0}"
            echo "2.1 In ${limitQuickFindTest} seconds, find saw ${nEmpties} empty Dirs in the tree ${delDir}."
            #Deleting dirs:
            if [ $nEmpties -gt 0 ]; then
                echo "Deleting empty directories first"
                echo "2.2 So it will start deleting empty dirs"
                #echo "Trying for ${limitDeleteTime} minutes"
                echo "Date starting:"
                date
                #AEG.1stIdea:LastGoodOne:timeout ${limitDeleteTime}m find -P ${delDir} -mindepth 1 -depth -type d -empty -delete
                #AEG.2ndIdea:timeout ${limitDeleteTime}m find -P ${delDir} -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -L1 -P${nPXargs} --replace=@ find -P @ -depth -type d -empty -delete
                #AEG:3rdIdea:Calling the function:
                deleteEmptyDirs
                echo "Date finishing:"
                date
            fi

            #-------------------------------------------
            #If it seems to be close to the end of deletion
            if [ $nFiles -eq 0 ] && [ $nEmpties -eq 0 ]; then
                echo "3.0 In ${limitQuickFindTest} seconds, empty dirs seen= ${nEmpties}, "
                echo "    and files seen=${nFiles}, then proceding into final stage"

                #Removing files:
                echo "3.1 Now deleting files in ${delDir} with munlink"
                #echo "Trying for ${limitDeleteTime} minutes"
                echo "Date starting:"
                date
                #AEG:NotUsingNow:timeout ${limitDeleteTime}m find -P ${delDir} -type f -o -type l -print0 | xargs -0 -P ${nPXargs} munlink
                #AEG:1stIdea:LastGoodOne:timeout ${limitDeleteTime}m find -P ${delDir} -type f -o -type l -print0 | xargs -0 -L${nFilesPerCore} -P ${nPXargs} munlink
                #AEG:2ndIdea:timeout ${limitDeleteTime}m find -P ${delDir} -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -L1 -P${nPXargs} --replace=@ find -P @ -type f -o -type l -print0 | xargs -0 -L${nFilesPerCore} -P ${nPXargs} munlink
                #AEG:3rdIdea:Calling the function:
                munlinkFilesAndLinks
                echo "Date finishing:"
                date

                #Removing empty directories:
                echo "3.2 now delting ${delDir} empty dirs left"
                #echo "Trying for ${limitDeleteTime} minutes"
                echo "Date starting:"
                date
                #AEG:1stIdea:LastGoodOne:timeout ${limitDeleteTime}m find -P ${delDir} -depth -type d -empty -delete
                #AEG:2ndIdea:timeout ${limitDeleteTime}m find -P ${delDir} -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -L1 -P${nPXargs} --replace=@ find -P @ -depth -type d -empty -delete
                #AEG:3rdIdea:Calling the function:
                deleteEmptyDirs
                echo "Date finishing:"
                date
                #Removing nasty files with rm -rf
                echo "4.0 As some nasty files/directories may not be recognized by the find/munlink procedure,"
                echo "    Here we remove everything with rm -rf during ${limitDeleteRMRF} minutes"
                echo "Date starting:"
                date
                timeout ${limitDeleteRMRF}m rm -rf ${delDir} 
                echo "Date finishing:"
                date
            fi


            #-------------------------------------------
            #Checking for the finished deletion and end of the cycle
            if ! [ -d $delDir ]; then
               echo "5.0 Deletion of the directory is finished: ${delDir}"
               cycles=$NMaxCycles
           fi
        done
    elif [ -f $delDir ]; then
        echo "${delDir} is a file. Deleting it"
        rm $delDir
    else
        echoWarning
        echo "${delDir} does not exists"
        echo " ---------------------------"
        echo ""
    fi
done

#-------------------------------------------
#-------------------------------------------
#Removing leftovers of auxiliary files and cancelling dependant job if neccesary
echo " "
echo "Removing rmLimit files from this submissions"
ls /tmp/*.${baseFileName}.rmLimit
rm /tmp/*.${baseFileName}.rmLimit
echo " "
echo "Removing toDelete files from this submissions"
ls /tmp/*.${baseFileName}.toDelete
rm /tmp/*.${baseFileName}.toDelete
if [ "$nothingDone" = "true" ]; then
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
else
    echo "At the end we have done many things. The flag is nothingDone=${nothingDone}"
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

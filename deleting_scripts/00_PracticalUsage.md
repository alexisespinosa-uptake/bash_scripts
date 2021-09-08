## Basic usage of the deleteFolders.sh script

---
### Generalities
The main script that submits a deletion job to the copyq is the file "submitDeletion.slm". This file itself also contains some explanation on how to use it,

This slurm script "submitDeletion.slm" should be copied to a working directory within user's /scratch space. Then, this new copy of the script should be modified/adapted for the user purposes and submitted via sbatch. We recommend to only modify/adapt the --job-name, --account options (at the top of the file), and the name of the directory/list to delete (at the bottom of the file). **IMPORTANT: if you use more than one slurm script to generate more than one deletion job, then --job-name of each job should be different**

The mentioned slurm script calls the real deletion script (`deleteManyFilesAndFolders.sh`). **IMPORTANT: Do not modify the `deleteManyFilesAndFolders.sh` file! The deleting operations it performs are not a recoverable so better proceed with caution!**

The file user.delete.list is an example of an auxiliary file in which user can specify a list of directories to be deleted.

---
### General usage:
Note: always use a different `--job-name` for each submitted script.

Start a session in hpc-data.pawsey.org.au

Copy the submitDeletion.slm script into a working directory from where you want to submit your job.

```bash
$ cp $MYGROUP/../deleting_scripts/submitDeletion.slm $MYGROUP/mySubmissioDir/myDeletion.slm
```

Modify the permissions of the new slurm script in order to be able to edit it:

```bash
$ cd $MYGROUP/mySubmissionDir
$ chmod 750 myDeletion.slm
```

Edit the `--job-name` of the script.

Edit the `--account` of the project.

Edit the variable `useDependantCycle` and set to `true` if you want the deletion script to send a recursive job until deletion of all indicated files is finished. This is needed only if you suspect that the deletion may take more than 24 hours.

Edit the `srun` command line at the bottom of the file:
	-	Replace the `dirToDeleteI` with the directory names or path/names to be deleted
	-   Replace the path to the text file containing the list of directories to be deleted
	-   Or both
```bash
srun -u -N ${SLURM_JOB_NUM_NODES} -n ${SLURM_NTASKS_PER_NODE} -c ${SLURM_CPUS_PER_TASK} ${deletingScriptName} $MYSCRATCH/case1 $MYSCRATCH/oldCases --list $MYGROUP/mySubmissionDir/toBeDeleted.txt
```

Submit the job:
```bash
sbatch myDeletion.slm
```

---
### Canceling the deleting job:

As the scripts my resubmit themselves in a dependant manner within a cycle, user should first identify both: the running job and the dependant job. Both of them can be identified in the queue:
```bash
$ squeue -u espinosa -p copyq
JOBID    USER     ACCOUNT     PARTITION            NAME EXEC_HOST ST     REASON   START_TIME     END_TIME  TIME_LEFT NODES   PRIORITY
2703557  espinosa pawsey0001  copyq           DeletingMyDirs hpc-data4  R       None     15:20:36     16:20:36      58:48     1       1002
2703558  espinosa pawsey0001  copyq           DeletingMyDirs       n/a PD Dependency          N/A          N/A    1:00:00     1       1002
```
It is clear that thera are two jobs with the same --job-name. One job is running while the dependant one is waiting in the queue.
In order to interrupt the cycle of dependant submissions, the waiting dependant job should be cancelled first:
```bash
$ scancel 2703558
```

And then the running afterwards:
```bash
$ scancel 2703557
```

```bash
$ squeue -u espinosa -p copyq
JOBID    USER     ACCOUNT     PARTITION            NAME EXEC_HOST ST     REASON   START_TIME     END_TIME  TIME_LEFT NODES   PRIORITY
```
Other wise, if the running job is cancelled first, then the dependant job will start and will send another dependat job before we can cancel it making it difficult to stop the submission cycle.
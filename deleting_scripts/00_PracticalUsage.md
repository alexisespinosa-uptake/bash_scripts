## Basic usage of the deleteFolders.sh script

---
### Generalities
The main script that submits a deletion job to the copyq is the file "submitDeletion.slm". This file itself also contains some explanation on how to use it,

This slurm script "submitDeletion.slm" should be copied to a working directory within user's /scratch space. Then, this new copy of the script should be modified/adapted for the user purposes and submitted via sbatch. We recommend to only modify/adapt the --job-name, --account options (at the top of the file), and the name of the directory/list to delete (at the bottom of the file). **IMPORTANT: if you use more than one slurm script to generate more than one deletion job, then --job-name of each job should be different**

The mentioned slurm script calls the real deletion script (deleteFolders.sh). **IMPORTANT: Do not modify the deleteFolders.sh file! Deleting is not a recoverable operation and should be performed with caution!**

The file user.delete.list is an example of an auxiliary file in which user can specify a list of directories to be deleted.

---
### General usage (delete a single directory):
Note: always use a different --job-name for each submitted script.

Start a session in hpc-data.pawsey.org.au

Copy the submitDeletion.slm script into a working directory from where you want to submit your job.

```
cp $MYGROUP/../deleting_scripts/submitDeletion.slm myDir/myDeletion.slm
```

Modify the permissions of the new slurm script in order to be able to edit it:

```
chmod 750 myDeletion.slm
```

Edit the --job-name of the script.

Edit the --account of the project.

Edit the srun line at the bottom of the file (the line that defines which directory is going to
be deleted). Basically, user just need to change the path/name of the directory to be deleted:
```
srun -u --export=all -N ${SLURM_JOB_NUM_NODES} -n ${SLURM_NTASKS_PER_NODE} -c ${SLURM_CPUS_PER_TASK} time -v ${deletingScriptName} /scratch/pawseyXXX/OpenFOAM/case1
```

Submit the job:
```
sbatch myDeletion.slm
```

---
### General usage (delete a multiple directories through a list):
Note: always use a different --job-name for each submitted script.

Start a session in hpc-data.pawsey.org.au

Copy the submitDeletion.slm script into a working directory from where you want to submit your job.

```
cp $MYGROUP/../deleting_scripts/submitDeletion.slm myDir/myDeletion.slm
```

Modify the permissions of the new slurm script in order to be able to edit it:

```
chmod 750 myDeletion.slm
```

Edit the --job-name of the script.

Edit the --account of the project.

If several directories are going to be deleted, you can add them to a list. The file containing the list
should be in your submission working directory or its path/name shoul be correctly specified in the srun command
at the bottom of the submission script. (See the example of the file with the list user.delete.list):
```
/scratch/pawseyXXXX/OpenFOAM/case1
/scratch/pawseyXXXX/OpenFOAM/ofv1706
/scratch/pawseyXXXX/OpenFOAM/elliptical
/scratch/pawseyXXXX/OpenFOAM/floating
/scratch/pawseyXXXX/OpenFOAM/validation_new
/scratch/pawseyXXXX/OpenFOAM/OF221
/scratch/pawseyXXXX/OpenFOAM/vis_remote
/scratch/pawseyXXXX/OpenFOAM/waveDyMFoam240
/scratch/pawseyXXXX/OpenFOAM/OF221_waveCurrent
/scratch/pawseyXXXX/OpenFOAM/3DnewSet
/scratch/pawseyXXXX/OpenFOAM/Zhou
/scratch/pawseyXXXX/OpenFOAM/2D
```

Comment out the line at the bottom (the line that defines a single directory to be deleted):
```
#srun -u --export=all -N ${SLURM_JOB_NUM_NODES} -n ${SLURM_NTASKS_PER_NODE} -c ${SLURM_CPUS_PER_TASK} time -v ${deletingScriptName} /scratch/pawseyXXX/OpenFOAM/case1
```

Activate the line at the bottom that defines the deletion using a list (edit the path/name of the list if neccessary):
```
srun -u --export=all -N ${SLURM_JOB_NUM_NODES} -n ${SLURM_NTASKS_PER_NODE} -c ${SLURM_CPUS_PER_TASK} time -v ${deletingScriptName} user.delete.list
```

Submit the job:
```
sbatch myDeletion.slm
```

---
### Canceling the deleting job:

As the scripts resubmit themselves in a dependant manner within a cycle, user should first identify both: the running job and the dependant job. Both of them shold be in the queue:
```
ssh espinosa@hpc-data.pawsey.org.au
espinosa@hpc-data3:/scratch/pawseyXXXX/espinosa/workDir> squeue -u espinosa -p copyq
JOBID    USER     ACCOUNT     PARTITION            NAME EXEC_HOST ST     REASON   START_TIME     END_TIME  TIME_LEFT NODES   PRIORITY
2703557  espinosa pawsey0001  copyq           DeletingMyDirs hpc-data4  R       None     15:20:36     16:20:36      58:48     1       1002
2703558  espinosa pawsey0001  copyq           DeletingMyDirs       n/a PD Dependency          N/A          N/A    1:00:00     1       1002
```
It is clear that thera are two jobs with the same --job-name. One job is running while the dependant one is waiting in the queue.
In order to interrupt the cycle of dependant submissions, the waiting dependant job should be cancelled first:
```
espinosa@hpc-data3:/scratch/pawseyXXXX/espinosa/workDir> scancel 2703558
```
And then the running afterwards:
```
espinosa@hpc-data3:/scratch/pawseyXXXX/espinosa/workDir> scancel 2703557
```
```
espinosa@hpc-data3:/scratch/pawseyXXXX/espinosa/workDir> squeue -u espinosa -p copyq
JOBID    USER     ACCOUNT     PARTITION            NAME EXEC_HOST ST     REASON   START_TIME     END_TIME  TIME_LEFT NODES   PRIORITY
```
Other wise, if the running job is cancelled first, then the dependant job will start and will send another dependat job before we can cancel it making it difficult to stop the submission cycle.


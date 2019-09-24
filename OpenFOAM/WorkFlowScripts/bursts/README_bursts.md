# Bursts scripts for old versions of OpenFOAM
These script were prepared to assist users of old versions of OpenFOAM to keep their number of files below a certain limit. All this because large amount of files affect the performance of our shared file system and because old versions of OpenFOAM do not have the **"-fileHandler collated"** option. This option is available in the latest versions of OpenFOAM and allows to reduce dramatically the number of result files generated.

The scripts follow the idea of running OpenFOAM for a small amount of time (bursts) in Magnus. And then submit a job to perform all possible postprocessing  of the recently generated results into Zeus. As a final stage of this postprocessing job is the taring of the needed files and remove/delete all the files that are no longer needed. While the postprocessing/deletion is being carried on by Zeus, Magnus would run another burst of the OpenFOAM solver and generate new result files. This type of "runtime postprocessing/deletion" may allow users to keep a reduced number of files (much more smaller than waiting for the case to be fully completed before starting postprocessing/deletion of files).

## Instructions
The instructions to use these scripts are:

### 1. Copy the files **_"\*.TO\_COPY\_TO\_CASE\_DIR"_**

```shell
user@magnus:> cd $MYSCRATCH/OpenFOAM/user-version/run/mycase
user@magnus:> cp $MYGROUP/bash_scripts/OpenFOAM/WorkFlowScripts/bursts/*.TO_COPY_TO_CASE_DIR .
user@magnus:> rename ".TO_COPY_TO_CASE_DIR" "" *.TO_COPY_TO_CASE_DIR
```

### 2. Edit the module definition files and define the module/container/installation to use
These scripts will be used on each computer to define the installation of openfoam to be used. Edit/adapt these script for the workflow to use the correct installations in zeus and magnus.

```shell
user@magnus:> vi defineModulesForMagnus.sh
user@magnus:> vi defineModulesForZeus.sh
```

### 3. Edit the **_runPrepare.sh_** script and submit
Edit the script to adapt it to your purposes:

```shell
user@magnus:> vi runPrepare.sh
```
Then submit it:

```shell
user@magnus:> sbatch runPrepare.sh
```

### 4. Edit the **_runCase.sh_** script and submit
This script is the main script for the whole process. A bit more detailed information of what you can modify/control from here is explained below.
##### Control variables and parameters:
So far, these are the OpenFOAM variables that can be modified in the **_"system/controlDict"_** of the case:

- startFrom, deltaT, writeInterval

These other variables have the following meaning/effect:

- allStartTime: will be the startTime for the first time the script is ran, but the value of startTime in the controlDict will change at every burst of the solution.
- forcedStartTime: if this variable is set to a positive value, then it will override the setting of the "allStartTime". The, allStartTime becomes a historical setting from which the user defined the offcial/real beginning of the case.
- allEndTime: will be the endTime to be reached and at which no more bursts of the OpenFOAM solver will be submitted. During the cycle of solution the endTime within the controlDict will vary, but will approach to this allEndTime at the end.
- burstRange: this defines the range in time that will be executed in every burst of Solution. This is VERY IMPORTANT parameter. With it, the startTime and endTime of every burst will be defined.

##### Reconstruction parameters




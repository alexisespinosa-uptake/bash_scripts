#!/bin/bash -l
#SBATCH -p copyq
#SBATCH --time=1:00:00
#SBATCH -M zeus

if ( [ $# -ne 3 ] ); then
   echo " "
   echo "fixDirectoryOwnership.sh [theDirectory] [theUser] [theNewGroupOwner]"
   echo " "
   exit
fi

theDirectory=$1
theUser=$2
theNewGroupOwner=$3

echo "Arguments given:"
echo "theDirectory=$theDirectory"
echo "theUser=$theUser"
echo "theNewGroupOwner=$theNewGroupOwner"

echo "Changing ownership of the given directory"
chgrp ${theNewGroupOwner} ${theDirectory}
chmod g+s ${theDirectory}

echo "Changing ownership of the files and subdirectories within the directory"
nohup find ${theDirectory} -user ${theUser} -exec chgrp ${theNewGroupOwner} {} \;
nohup find ${theDirectory} -user ${theUser} -type d -exec chmod g+s {} \;

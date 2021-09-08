#!/bin/bash
if ( [ $# == 0 ] || [ $# == 1 ] || [ $# -gt 2 ] ); then
   echo " "
   echo "fix.filesysten.permission.sh [ProjectGroupID] [Filesystem]"
   for x in $(groups)
          do
                                                                                                #echo $x
                                                                                                        if [ -d /group/$x ];
                                                                                                                        then
                                                                                                                                        echo "* $x"
                                                                                                                                                fi
                                                                                                                                                    done
                                                                                                                                                        exit
                                                                                                                                                    fi


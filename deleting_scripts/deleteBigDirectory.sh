#!/bin/sh
currentScript=`basename \$0`
if [ $# == 0 ]; then 
    echo " "
	echo "$currentScript [dir1ToDelete dir2ToDelete ...]"
	echo " "
	echo "What?"
    echo "Will delete the indicated directory (or directories) with many files"
	exit
fi

for var in "$@"; do
    echo "Deleting $var"
    find -P $var -type f -print0 -o -type l -print0 | xargs -0 munlink
    find $var -depth -type d -empty -delete
done

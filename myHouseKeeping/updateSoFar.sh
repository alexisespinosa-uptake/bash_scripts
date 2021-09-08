#!/bin/bash

i=0
dirToUpdate[$i]=/group/pawsey0001/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0004/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0100/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0106/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0115/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0126/deleting_scripts
((i++))
dirToUpdate[$i]=/group/pawsey0224/deleting_scripts
((i++))
dirToUpdate[$i]=/group/director2068/deleting_scripts
((i++))
dirToUpdate[$i]=/group/y95/deleting_scripts
((i++))

NDirs=$(( $i -1 ))
for j in `seq 0 ${NDirs}`; do
    echo "Updating ${dirToUpdate[$j]}" 
    chmod 755 ${dirToUpdate[$j]}
    chmod 755 ${dirToUpdate[$j]}/*
    rm ${dirToUpdate[$j]}/deleteFolders.sh
    rm ${dirToUpdate[$j]}/submitDeletion.slm
    rm ${dirToUpdate[$j]}/user.delete.list
    rm ${dirToUpdate[$j]}/00_PracticalUsage.md
    cp deleteFolders.sh ${dirToUpdate[$j]}
    cp submitDeletion.slm ${dirToUpdate[$j]}
    cp 00_PracticalUsage.md ${dirToUpdate[$j]}
    cp user.delete.list ${dirToUpdate[$j]}
    chmod 555 ${dirToUpdate[$j]}/*
    chmod 555 ${dirToUpdate[$j]}
done

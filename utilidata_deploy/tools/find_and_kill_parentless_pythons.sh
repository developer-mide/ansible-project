#!/bin/bash


LIST="$( ps xafuw | grep '[0-9] /usr/bin/python3.8' | grep -v '/usr/local/bin/jtop' )"

echo "$LIST"

#the command below doesn't work because it also finds the jtop processes:
#PPPIDS=$( ps -o ppid= -o pid= $( pidof python3.8 ) | grep '^\W*1' | awk '{ print $2 }' )

PPPIDS=$( echo "$LIST" | awk '{ print $2 }' )

echo

echo kill $PPPIDS


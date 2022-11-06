#!/bin/bash

#./spinx/read_ringbuf 0 0 2>&1 >/dev/null | while read L; do echo $( uptime ) "$L"; done

mkdir -p snaps/

while true; do

	echo "Reading ringbuffer to warm up..."
	timeout 1.0 ./spinx/read_ringbuf 0 0 2>&1 >/dev/null | ( read L; echo $( uptime ) "$L"; )
	sleep 2

	F="./snaps/snapclean_$( date '+%s' )_$( hostname ).bin"
	echo "Attempt a clean snapshot as $F ..."
	timeout 0.1 ./spinx/read_ringbuf 1 32000 1 2 >$F

	echo "Done, waiting 2 seconds ..."
	sleep 2
done

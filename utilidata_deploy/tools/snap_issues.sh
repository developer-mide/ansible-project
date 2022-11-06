#!/bin/bash

#./spinx/read_ringbuf 0 0 2>&1 >/dev/null | while read L; do echo $( uptime ) "$L"; done

mkdir -p snaps/

while true; do

	echo "Reading ringbuffer, waiting for anomalies ..."
	./spinx/read_ringbuf 0 0 2>&1 >/dev/null | ( read L; echo $( uptime ) "$L"; )

	F="./snaps/snap_$( date '+%s' )_$( hostname ).bin"
	echo "Potentially interesting issue detected, saving about a second as $F ..."
	timeout 0.6 ./spinx/read_ringbuf 1 16000 1 2 >$F

	echo "Done, waiting 2 seconds ..."
	sleep 2
done

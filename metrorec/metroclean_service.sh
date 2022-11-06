#!/bin/bash

set -e  # Exit on error
set -u  # Exit on unset variable

METROEXEC=./metrorec
BUFDIR=/tmp/buftest

# NOTE: Neither touch, nor compress, the number of chunks you want to be able to process with the current read_metrobuf

CHUNKS_DONT_TOUCH=210	# Number of chunk directories to not process at all
CHUNKS_DONT_COMPR=420	# Number of chunk directories to keep uncompressed
# DISK_FREE_GOAL=40 # If more than CHUNKS_DONT_TOUCH are present, delete old chunks until DISK_FREE_GOAL (in GB) are free on disk


KEEP_CHANNELS=(
	"IA.int32*"
	"IB.int32*"
	"VA.int32*"
	"VB.int32*"
	"meta.bin*"
)
#echo ${KEEP_CHANNELS[@]}

EXCLUDE_KEEPS_FROM_FIND="${KEEP_CHANNELS[@]/#/-not -name }"
#echo "$KEEP_FIND"

cd "$BUFDIR"


while true; do

sleep 600

# Delete channels we don't need to keep long-term
find ./ -mindepth 1 -maxdepth 1 -type d -name '0*' | sort -n | head -n "-${CHUNKS_DONT_TOUCH}" |
while read CHUNK; do
	#echo "--- Cleanup $CHUNK"
	find $CHUNK $( for (( c=0; c<4; c++ )) do read N; echo $N; done ) \
		-type f $EXCLUDE_KEEPS_FROM_FIND | xargs -r rm
done

# Compress older channels
find ./ -mindepth 1 -maxdepth 1 -type d -name '0*' | sort -n | head -n "-${CHUNKS_DONT_COMPR}" |
while read CHUNK; do
	#echo "--- Compress $CHUNK"
	find $CHUNK $( for (( c=0; c<4; c++ )) do read N; echo $N; done ) \
		-type f -not -name '*.gz' | xargs -r gzip
done


# TODO: Delete oldest channels entirely to meet DISK_FREE_GOAL


done


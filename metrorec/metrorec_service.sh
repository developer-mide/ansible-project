#!/bin/bash

set -e

METROEXEC=./metrorec
BUFDIR=/tmp/buftest
CHUNKSECS=300

#mkdir -p "$BUFDIR"  # Should the service create the buffer directoy?

# Find highest chunkdir number in $BUFDIR
read N < <( { echo "00"; ls -1 "$BUFDIR"; } | grep '^[0-9][0-9]*' | tail -n 1 | sed -e 's/^0*//' )
#echo "[$N]"
N=$(( $N + 1 ))
read CHUNKDIR< <( "$METROEXEC" "$BUFDIR" "$N" )

# We consider metrorec's mkdir and meta file creation upon receiving the first UDP packet as atomic enough for now
# And listening to the UDP port acts as MUTEX, so we don't need to create the directory here and instead
# rely on metrorec for that, this should entirely avoid empty chunk directories
#mkdir "$BUFDIR/$CHUNKDIR" || {
#    echo "Chunkdir '$BUFDIR/$CHUNKDIR' already exists - race condition?"
#    exit 33
#}
''
# launch cleanup code / garbage collector in background?
# MIN_CHUNKS_TO_KEEP=5
# MAX_CHUNKS_TO_KEEP ?
# DISK_FREE_GOAL=40 # If more than MIN_CHUNKS_TO_KEEP are present, delete old chunks until DISK_FREE_GOAL (in GB) are free on disk
# It might be much more systemd-compatible if the cleanup & transfer service(s) are separate

exec ./metrorec "$BUFDIR" "$N" "$CHUNKSECS" >/dev/null # || true

# kill cleanup / garbage collector code?

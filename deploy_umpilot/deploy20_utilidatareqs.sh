#!/bin/bash

set -e

if [ $# -lt 1 ]; then
	echo "Usage: $0 hostname [port [username]]"
	exit 1
fi

TARGETHOST="${1:-192.168.55.1}"
PORT="${2:-22}"
USERNAME="${3:-utilidata}"
TGT="${USERNAME}@${TARGETHOST}"

ssh -t -p "$PORT" "$TGT" "dpkg -l | cat" >> log/${TARGETHOST}_dpkg_begin_utilidatareqs

echo "==========================="
echo "SSH'ing into $TGT to install developer tools..."

ssh -t -p "$PORT" "$TGT" "

echo -e '\nLogin successful ! Installing Utilidata requirements, e.g. mqtt (from Frank Dupuis) ...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo apt-get install -y --no-install-recommends mosquitto mosquitto-clients awscli jq

" | tee -a log/${TARGETHOST}_utilidatareqs

echo -e "\nFirst ssh session completed.\n\n"

ssh -t -p "$PORT" "$TGT" "dpkg -l | cat" >> log/${TARGETHOST}_dpkg_endof_utilidatareqs

echo "End of script"


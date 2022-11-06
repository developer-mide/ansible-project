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


echo "==========================="
echo "SSH'ing into $TGT to install developer tools..."

ssh -t -p "$PORT" "$TGT" "

echo -e '\nLogin successful ! Running apt-get update, upgrade and autoremove ...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo apt-get update

dpkg -l | cat

sudo apt-get -y upgrade

sudo apt-get -y autoremove --purge

dpkg -l | cat

" | tee -a log/${TARGETHOST}_upgrade

echo -e "\nFirst ssh session completed.\n\n"

echo "End of script"

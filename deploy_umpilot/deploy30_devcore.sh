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

echo -e '\nLogin successful ! Installing developer tools...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo apt-get -y install g++ strace

sudo mkdir -p /mnt/ssd/buftest/
sudo chown utilidata:utilidata /mnt/ssd/buftest/
"

echo -e "\nFirst ssh session completed.\n\n"

echo "End of script"

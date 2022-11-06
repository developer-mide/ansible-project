#!/bin/bash

# This script used to run in a cronjob on the Lake Placid units, but the microhard routers
# have issues with frequent https hits (memory leak or something similar), and the Web UI
# becomes unresponsive. Needs to be replaced with AT commands over the SSH interface
# (then we can disable the https interface alltogether, also solves the self-signed
#  certificate nightmare, and we just use ssh fingerprints & keys instead)

mkdir -p microhard_logs/
cd microhard_logs/

PW='xxx' # deleted from commited codebase

wget -q --no-check-certificate --user="admin" --password="$PW" https://192.168.168.1:4443/cgi-bin/webif/carrier-status.sh
wget -q --no-check-certificate --user="admin" --password="$PW" https://192.168.168.1:4443/cgi-bin/webif/system-info.sh



#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy/ 

echo "SSH'ing into $TGT to run sudo /opt/nvidia/jetson-io/jetson-io.py ..."
ssh -t "utilidata@$TGT" "
echo $? > 'deploy/ran_$( basename $0 )' # need to do it here because the next command reboots the system
sudo /opt/nvidia/jetson-io/jetson-io.py
" || true

touch "log/${TGT}_$( basename $0 )"


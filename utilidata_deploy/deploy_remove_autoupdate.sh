#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy/ 

echo "SSH'ing into $TGT to reove auto-update related packages"
ssh -t "utilidata@$TGT" "
sudo apt purge update-notifier-common
sudo apt autoremove --purge
"

ssh "utilidata@$TGT" "echo $? > 'deploy/ran_$( basename $0 )'"

touch "log/${TGT}_$( basename $0 )"

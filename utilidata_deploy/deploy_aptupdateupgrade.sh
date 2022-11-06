#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy/ 

echo "SSH'ing into $TGT to update all software packaged..."
ssh -t "utilidata@$TGT" "
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove --purge

sudo apt install tmux pv inotify-tools atop htop nocache elinks strace ntp
sudo apt install gnuplot octave
"

ssh "utilidata@$TGT" "echo $? > 'deploy/ran_$( basename $0 )'"

touch "log/${TGT}_$( basename $0 )"


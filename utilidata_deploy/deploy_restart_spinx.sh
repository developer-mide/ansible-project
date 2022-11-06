#!/bin/bash

set -e

TGT="${1:-jnx30d5}"
PORT="${2:-22}"

ssh -p "$PORT" "utilidata@$TGT" mkdir -p deploy

ssh -p "$PORT" -t "utilidata@$TGT" "
sudo systemctl stop spinx
sleep 2
du -hs /dev/shm/ring.*
sleep 2
sudo systemctl start spinx
sleep 2
du -hs /dev/shm/ring.*
"

touch "log/${TGT}_$( basename $0 )"

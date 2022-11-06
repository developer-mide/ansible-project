#!/bin/bash

set -e

TGT="${1:-jnx30d5}"
PORT="${2:-22}"

ssh -p "$PORT" "utilidata@$TGT" mkdir -p deploy

F="spinx_$TGT.tar.bz2"
if [ "$3" == "" ]; then
#ssh user@xavierdev1 tar cvfj "$F" spinx/
#scp -p "user@xavierdev1:$F" spinxes/
ssh user@jnx30d1 tar cvfj "$F" spinx/
scp -p "user@jnx30d1:$F" spinxes/
fi
scp -P "$PORT" -p "spinxes/$F" "utilidata@$TGT:deploy/"
ssh -p "$PORT" -t "utilidata@$TGT" "
sudo systemctl stop spinx
sleep 1
killall spinx spinx_unity
tar xvfj 'deploy/$F'
sleep 1
sudo systemctl start spinx
true # return true if we reach this point (spinx service might not be installed yet)
"

touch "log/${TGT}_$( basename $0 )"

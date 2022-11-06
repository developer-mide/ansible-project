#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

F="spidev_spinx.conf"
F2="spinx.service"
ssh "utilidata@$TGT" mkdir -p deploy || true
scp -p "files/$F" "files/$F2" "utilidata@$TGT:deploy/"
echo "SSH'ing into $TGT to put $F and $F2 in place and start spinx service, please provide $TGT's password below"
ssh -t "utilidata@$TGT" "sudo cp 'deploy/$F' /etc/modules-load.d/   ;
                         sudo cp 'deploy/$F2' /etc/systemd/system/  ;
			 sudo modprobe spidev
			 sudo systemctl enable spinx
                         sudo systemctl start spinx
			 sleep 5
			 sudo systemctl status spinx"

touch "log/${TGT}_$( basename $0 )"

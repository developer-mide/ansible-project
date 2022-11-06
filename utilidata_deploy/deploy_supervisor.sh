#!/bin/bash

# Can only happen after Washo did his magic... of dropping his package?

set -e

TGT="${1:-jnx30d5}"

F="sgc_supervisor.conf"
ssh -t "utilidata@$TGT" "sudo apt install supervisor
mkdir -p pilot/sgc_pilot/"
scp -p "files/$F" "utilidata@$TGT:deploy/"
scp -p "Install_Instructions/start_monitoring.py" "utilidata@$TGT:/home/utilidata/pilot/sgc_pilot/"
echo "SSH'ing into $TGT to put sgc_pilot_supervisor.conf in place, please provide $TGT's password below"
ssh -t "utilidata@$TGT" "
sudo cp "deploy/$F" /etc/supervisor/conf.d/sgc_pilot_supervisor.conf
sudo systemctl restart supervisor
"

touch "log/${TGT}_$( basename $0 )"


#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy

F="authorized_keys"
scp -p "files/$F" "utilidata@$TGT:deploy/"
ssh -t "utilidata@$TGT" "ssh-keygen
cp -p deploy/$F ~/.ssh/
#sudo vim /etc/ssh/sshd_config
sudo sed -i -e 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
"

touch "log/${TGT}_$( basename $0 )"

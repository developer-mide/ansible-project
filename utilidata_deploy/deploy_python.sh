#!/bin/bash

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy/ 

echo "SSH'ing into $TGT to install correct python version and related packages..."
ssh -t "utilidata@$TGT" "
sudo apt-get install python3.8
sudo apt-get install python3.8-dev
sudo apt-get install python3-setuptools
wget -c https://files.pythonhosted.org/packages/b7/2d/ad02de84a4c9fd3b1958dc9fb72764de1aa2605a9d7e943837be6ad82337/pip-21.0.1.tar.gz
tar -xzvf pip-21.0.1.tar.gz
cd pip-21.0.1
sudo python3.8 setup.py install

sudo -H pip install -U jetson-stats

sudo -H pip uninstall numpy
sudo -H pip install numpy
"

ssh "utilidata@$TGT" "( pip3 --version ; pip --version ; echo 'test' >&2 ) > 'deploy/ran_$( basename $0 )' 2>&1"

touch "log/${TGT}_$( basename $0 )"


#!/bin/bash

cd "$( dirname $0 )" # change to the directory this script is located in
pwd

RPATH='~/TEENSPI_metrorec/'  # Path on the remote side
RUSERHOST="${1:-user@localhost}"  # remote user and hostname as used by rsync & ssh
RPORT=${2:-2222}                  # port ssh can be reached at
REXEC=${3:-testreceiver}          # tool/executable to run on remote after build
shift 3

ssh -p "$RPORT" "$RUSERHOST" mkdir -p "$RPATH"

#rsync -e "ssh -p $RPORT" -av ../metrorec "$RUSERHOST:$RPATH"
scp -P "$RPORT" -rp ../metrorec "$RUSERHOST:$RPATH"

ssh -p $RPORT "$RUSERHOST" "
cd ${RPATH}metrorec &&
./build_all.sh &&
./$REXEC $@
"

scp -P "$RPORT" -p "$RUSERHOST:${RPATH}metrorec/data.int32" .

#!/bin/bash

# Can only happen after Washo did his magic... of dropping his package?

set -e

TGT="${1:-jnx30d5}"
PORT="${2:-22}"

ssh -p "$PORT" -t "utilidata@$TGT" "
echo
echo
date
uname -a
uptime
cd spinx/
python3.8 -u sgc_metrology_live.py
" 2>&1 | tee -a "log/${TGT}_$( basename $0 )"


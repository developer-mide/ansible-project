#!/bin/bash

# Can only happen after Washo did his magic... of dropping his package?

set -e

TGT="${1:-jnx30d5}"

ssh -t "utilidata@$TGT" "sudo shutdown -r now"

touch "log/${TGT}_$( basename $0 )"


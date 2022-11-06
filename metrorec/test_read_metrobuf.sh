#!/bin/bash

set -e

BUFDIR=/tmp/buftest
./read_metrobuf "$BUFDIR" 0 0 80 81 82 83 21 22 23 24 25 26 27 28 | dd bs=$(( 12 * 4 )) count=32000 of=data.int32


#!/bin/bash

set -e

killall metrorec || true

BUFDIR=/tmp/buftest
mkdir -p "$BUFDIR"
./metrorec "$BUFDIR" 5 100

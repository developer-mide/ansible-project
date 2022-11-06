#!/bin/bash

set -e

{
    echo "# This file is auto-generated by build_all.sh using bufferchannels.h"
    echo "# Nevertheless, it is also under version control for convenience."
    echo 'channel_names = {'
    grep -e "^#define" -e '^//' bufferchannels.h | sed -r -e 's/#define (\S*)(\s*)(\S*)/\t"\1"\2: \3, /' -e 's%//%\t#%'
    echo '}'
} >bufferchannels.py

#gcc examplereceiver.c -o examplereceiver

g++ simstream.cpp     -Wall  -o simstream
g++ testreceiver.cpp  -Wall  -o testreceiver
g++ metrorec.cpp      -Wall  -o metrorec
g++ read_metrobuf.cpp -Wall  -o read_metrobuf
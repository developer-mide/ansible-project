#!/bin/bash

S1="AT+MSMNAME?
AT+MSMNAME=TestDevice
AT+MSMNAME?
AT&W
ATH"

# Get List of all commands:
S2="ATL\n"

if true; then
#  ./scan_commands.sh | tee ATL
BS="$( echo -e "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"; )"
grep " AT+" ATL_cat4 |
	grep -v -e "MMM" -e "MWSCAN" -e "MMSVRCELL" -e "MMNEBCELL" | # the MMMGL command causes the device to reboot reliably. MWSCAN is pretty weird in the manual :) (no help, but the output of Microhard's environment)
{ while read ATCOM DESC; do
	#echo -e "=========================================\n$ATCOM\n";
	#( echo -n -e "${ATCOM}?=?"; sleep 3; ) | ssh -T admin@192.168.168.1
	echo -n -e "${ATCOM}?=?"; sleep 0.1; echo "$BS"; sleep 0.1
done ; sleep 10; } | ssh -T admin@192.168.168.1

exit
fi

# Get status and info for command:
S3="AT+MFGEN?=?\\b"

# Select set of commands to execute:
S="$S2"

( echo -n -e "$S"; sleep 5; ) |
ssh -t admin@192.168.168.1
#ssh -T admin@192.168.168.1


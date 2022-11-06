#!/bin/bash

set -e  # Exit on error
set -u  # Exit on unset variable

S1="AT+MSMNAME?
AT+MSMNAME=TestDevice
AT+MSMNAME?
AT&W
ATH"

# Get List of all commands:
S2="ATL\n"

if false; then
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

UNITNAME=$1

# Get status and info for command:
S3="AT+MFGEN?=?\\b"

SHARDRESET="
AT+MSRTF=0
AT+MSRTF=1
"  # This sequence of commands resets the router to NVRAM default settings

##### Master config:

# Local, freshL
SSHPORT=22
SSHHOST="192.168.168.1"

# Jumphost, fresh:
SSHPORT=1222
SSHHOST="localhost"

export SSHPASSCONFIG="-e"
export SSHPASS=admin
#export SSHPASS=nvidia

if [ "${2:-}" != "" ]; then
# Jumphost, re-run:
SSHPORT=2223 ; export SSHPASSCONFIG="-f NEWSSHPASS"
fi
REBOOT="AT+MSREB	# Reboot router"
if [ "${3:-}" != "" ]; then
	REBOOT=
fi

# Initial configurations:
PORTFORWARD1="0,192.168.168.55,22,0,32155,1"  # Last arugment is SNAT, necessary if alternative default route (e.g. WiFi) exists on Jetson?
PORTFORWARD2="0,192.168.168.55,22,0,32055,0"  # Last arugment is SNAT, necessary if alternative default route (e.g. WiFi) exists on Jetson?
S4="
AT+MSSYSI	# Query IMEI & SIMID right in the beginning (perhaps it's already available?)

AT+MNPORT=0,1,0,0,0,0,1,0,0	# Set Ethernet Port to manual, no auto-negotiation, 100 Mbit Half/Duples
AT+MSSERVICE=0,0	# Disable FTP service
AT+MSSERVICE=1,0	# Disable Telnet service (just to be sure)
AT+MSSERVICE=2,1,2223	# Set SSH to port 2223
AT+MSWEBUI=2,4443	# Set WebUI to https only, port 4443 (doesn't work!)
AT+MMDNS=1,1,8.8.8.8,8.8.8.4	# Disable Carrier Provided DNS, and provide alternative
AT+MSNTP=1		# Enable NTP (defaults to pool.ntp.org, 1 hr update interval)
AT+MFPORTFWD=jnx22sn,ADD,$PORTFORWARD1	# Port Forwarding. Last argument in SNAT, might need to be enabled (1) if N150 Wifi is also used as GW
AT+MFPORTFWD=jnx22sn,EDIT,$PORTFORWARD1	# Port Forwarding. Last argument in SNAT, might need to be enabled (1) if N150 Wifi is also used as GW
AT+MFPORTFWD=jnx22,ADD,$PORTFORWARD2	# Port Forwarding. Last argument in SNAT, might need to be enabled (1) if N150 Wifi is also used as GW
AT+MFPORTFWD=jnx22,EDIT,$PORTFORWARD2	# Port Forwarding. Last argument in SNAT, might need to be enabled (1) if N150 Wifi is also used as GW
AT+MSPWD=$(<NEWSSHPASS),$(<NEWSSHPASS)	# <New Password>,<Confirm Password>
AT+MMAPN=1,so01.vzwstatic	# Set the APN for SIM Card 1
AT+MSSYSLOG=192.168.168.55,514	# Set the syslog server (jnx22)
AT+MFGEN1=0,1,1,1		# Firewall: Allow Remote Management, remote access (port forwarding) and  LAN outgoing traffic 

AT&W			# Activate above changes - careful, not really necessary, on connection abort, things above might still activate! (from buffer?)

AT+MNPORT	# Query Ethernet Port config
AT+MSSERVICE	# Query Service config
AT+MSWEBUI	# Query WebUI config
AT+MMDNS
AT+MSNTP
AT+MFPORTFWD	# Query Port Forwarding Statusa
AT+MSSYSLOG
AT+MFGEN1
AT+MNSTATUS	# Retrieve Network Status
AT+MSSYSI	# Retrieve System Summary information
AT+MNSTATUS	# Retrieve network status
AT+MMBOARDTEMP	# Retrieve Board Temperature
AT+MSGMR	# Retrieve modem Record Information

$REBOOT
"

# No GPIO AT command yet - consider rebooting the router for "system reset" ?

# Select set of commands to execute:
S="$S4"

#HKEYFILE=$(mktemp -p hostkeys/)
HKEYFILE="./mhdb/${UNITNAME}_hostkey"
SLOGFILE="./mhdb/${UNITNAME}_log"

{

echo -e "\n\n\n========================================================="
echo -e "===   New Configuration Session with $SSHHOST $SSHPORT ==="
echo -e "=========================================================\n\n\n"

echo -e "\n===  Configuration Session Started: $(date)"

( echo -n -e "$S" | sed -e 's/\s.*//'; sleep 45; ) |
	sshpass $SSHPASSCONFIG ssh -t -p "$SSHPORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=$HKEYFILE admin@$SSHHOST
#ssh -T admin@192.168.168.1

echo -e "\n===  Configuration Session Ended: $(date)"
} | tee -a $SLOGFILE #master_config.log


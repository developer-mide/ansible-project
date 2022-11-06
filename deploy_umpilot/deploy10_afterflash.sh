#!/bin/bash

set -e  # Exit on error
set -u  # Exit on unset variable

if [ $# -lt 1 ]; then
	echo "Usage: $0 <jnx22uXXXX> [ipaddress-or-hostname [port [username [path-to-key-file]]]]"
	exit 1
fi

NEWHOSTNAME="${1}"
IPADDRESS="${2:-192.168.55.1}"
PORT="${3:-22}"
USERNAME="${4:-utilidata}"
TGT="${USERNAME}@${IPADDRESS}"
AUTHKEYFILE="${5:-files/authorized_keys}"
AUTHKEYS="$(<$AUTHKEYFILE)" || {
	echo "Authorized_keys file not found or permission issues?"
	echo "Bailing out because this will make unattended setup impossible."
	exit 2
}

DBDIR="db/"
UNIT_HOSTKEYFILE="${DBDIR}${NEWHOSTNAME}_hostkey"
UNIT_AUTHKEYFILE="${DBDIR}${NEWHOSTNAME}_authorized_keys"
UNIT_PRIVKEYFILE="${DBDIR}${NEWHOSTNAME}_${USERNAME}_ed25519"
UNIT_PRIVKEYFILE="${DBDIR}${NEWHOSTNAME}_${USERNAME}_ed25519"
ANSIBLE_AUTHKEYFILE="${6:-files/ansible1_authorized_keys}"
ANSIBLE_USERNAME="ansible1"
ANSIBLE_PKEYFILE="${DBDIR}${NEWHOSTNAME}_${ANSIBLE_USERNAME}_ed25519"

# TODO:
#   First login attempt: combine UNIT_PRIVKEY with existing keys? Does that make sense?
#   ...
# IDEMPOTENT flag? (basically a configuration from scratch, but keeping already generated keys intact...)
FLAG_IDEMPOTENT=true
# FRESHINSTALL flag? (re-generates all keys etc? what about host key?)
# Reflash: need to delete old hostkey?
FLAG_NEWKEYS=false
# PRODUCTION flag? (no developer keys?) Could point to empty key file...
#
# encrypted syslog remote target? (Also for fail2ban or other intrusion detection etc?)

[ -e "${UNIT_PRIVKEYFILE}" ] && $FLAG_NEWKEYS &&
	mv "${UNIT_PRIVKEYFILE}" "${UNIT_PRIVKEYFILE}.$(stat -c %Y ${UNIT_PRIVKEYFILE})"
[ -e "${ANSIBLE_PKEYFILE}" ] && $FLAG_NEWKEYS &&
	mv "${ANSIBLE_PKEYFILE}" "${ANSIBLE_PKEYFILE}.$(stat -c %Y ${ANSIBLE_PKEYFILE})"

if [ ! -e "${UNIT_PRIVKEYFILE}" ]; then
	ssh-keygen -t ed25519 -N "" -C "auto-generated_${USERNAME}@${NEWHOSTNAME}" -f "${UNIT_PRIVKEYFILE}"
fi
if [ ! -e "${ANSIBLE_PKEYFILE}" ]; then
	ssh-keygen -t ed25519 -N "" -C "auto-generated_${ANSIBLE_USERNAME}@${NEWHOSTNAME}" -f "${ANSIBLE_PKEYFILE}"
fi
SSH_ADDCERTFILES=("-o" "IdentityFile ${UNIT_PRIVKEYFILE}")
for F in "${UNIT_PRIVKEYFILE}".[^p]*  ~/.ssh/id_dsa ~/.ssh/id_ecdsa ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do if [ -e "$F" ]; then
	SSH_ADDCERTFILES+=("-o" "IdentityFile $F");
fi; done
AUTHKEYS="${AUTHKEYS}
$(<$UNIT_PRIVKEYFILE.pub)" || {
	echo "Per-unit Authorized_keys file not found or permission issues?"
	echo "Bailing out because this might be unintended or make unattended setup impossible."
	exit 3
}
ANSIBLE_AUTHKEYS="$(<$ANSIBLE_AUTHKEYFILE)
$(<${ANSIBLE_PKEYFILE}.pub)"

WLAN0_FILE="files/wifi_config"
WLAN0_OPTIONS=""
if [ -e "$WLAN0_FILE" ]; then
	WLAN0_OPTIONS="$(<$WLAN0_FILE)"
fi
# TODO: Support individual WIFI (and ethernet?) config files per unit (as option), to maintain idempotency when updating other things?

if [ ! -e "${UNIT_HOSTKEYFILE}" ]; then
	echo "Unit's host key file (${UNIT_HOSTKEYFILE}) not found, populating with ssh-keyscan..."
	ssh-keyscan -t ed25519 -p "$PORT" "$IPADDRESS" | grep -v "^#" | ( read H T K ; echo "* $T $K" > "${UNIT_HOSTKEYFILE}"; )
fi


#SSH_OPTS=("-o" "HashKnownHosts no" "-o" "UserKnownHostsFile ${UNIT_HOSTKEYFILE}" "-i" "${UNIT_PRIVKEYFILE}")
#SSH_OPTS=("-o" "HashKnownHosts no" "-o" "UserKnownHostsFile ${UNIT_HOSTKEYFILE}" "-o" "CertificateFile ${UNIT_PRIVKEYFILE}")
SSH_OPTS=("-o" "HashKnownHosts no" "-o" "UserKnownHostsFile ${UNIT_HOSTKEYFILE}")

echo "${SSH_ADDCERTFILES[@]}"

echo "==========================="
echo "SSH'ing into $TGT to deploy authorized_keys..."
echo "If this is the first time connecting to the newly flashed unit, SSH should ask you to accept the new host key first."
echo "Also, no authorized_keys should be deployed yet, therefore ssh should ask you for the user password."

#ssh -t "${SSH_OPTS[@]}" -p "$PORT" "$TGT" "
ssh -t "${SSH_OPTS[@]}" "${SSH_ADDCERTFILES[@]}" -p "$PORT" "$TGT" "

echo -e '\nLogin successful !'
echo -e 'Providing public SSH keys for automatic login...'

mkdir -p -m 700 ~/.ssh/
echo '$AUTHKEYS' >~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
" || { echo "
If the SSH command failed due to an offending host key, which is expected
IF ANOTHER UNIT WAS CONFIGURED WITH THE SAME IP ADDRESS BEFORE,
the following command should be run:

ssh-keygen -f ~/.ssh/known_hosts -R '${IPADDRESS}'
"
exit 11
} # Consider removing or changing this error message, no longer applicable with UNIT_HOSTKEYFILE

echo "$AUTHKEYS" > "${UNIT_AUTHKEYFILE}"

# Using wildcard in per-host key file to allow for IP change: (now taken care of by ssh-keyscan above)
##sed -i -r -e 's/^\S* /* /' "${UNIT_HOSTKEYFILE}"
#( read H T K < "${UNIT_HOSTKEYFILE}" ; echo "* $T $K" > "${UNIT_HOSTKEYFILE}"; ) # no sed dependency

echo -e "\nFirst ssh session completed.\n\n"

# From now on, the specific private key file should suffice:
SSH_OPTS+=("-i" "${UNIT_PRIVKEYFILE}")


echo "==========================="
echo "SSH'ing into $TGT to test automatic login, and if successful, disable password authentication for SSH..."

ssh -t "${SSH_OPTS[@]}" -p "$PORT" "$TGT" -o "PasswordAuthentication no" "

echo -e '\nLogin successful ! Disabling ssh password authentication...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo sed -i -e 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload sshd
"

echo -e "\nSecond ssh session completed.\n\n"
sleep 1

# Todo: This "third SSH session" includes network changes,
#  so the SSH session might be interrupted while executing these changes?
#  Does it make sense to run this script in a detached way, so that it may complete in that case?
#  Timeout/lock mechanism might be necessary to avoid multiple instances
# all of the above doesn't seem to happen over the USB interface. TBD what happens over ethernet

echo "==========================="
echo "SSH'ing into $TGT to set hostname, disable automatic updates, remove network manager, disable IPv6, config ifupdown, create ansible1 user ..."
#echo "install NTP temporary supsended until hwclock/RTC issues are figured out'

ssh -t "${SSH_OPTS[@]}" -p "$PORT" "$TGT" -o "PasswordAuthentication no" "

echo -e '\nLogin successful !'

echo -e '\nSetting hostname to $NEWHOSTNAME ...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo hostnamectl set-hostname $NEWHOSTNAME
sudo sed -Ei 's/^127\.0\.1\.1\s.*/127.0.1.1\t$NEWHOSTNAME/' /etc/hosts

if [ ! -e /etc/network/interfaces ] || $FLAG_IDEMPOTENT; then
echo -e '\nNo /etc/network/interfaces, creating default one to be prepared for network manager removal:'
echo '
source /etc/network/interfaces.d/*
' | sudo tee /etc/network/interfaces
fi

echo -e '\nDisabling IPv6 ...'
echo '# Completely disable IPv6 to avoid shadow networks
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
' | sudo tee /etc/sysctl.d/95-sgc-disable-ipv6.conf
sudo sysctl --system

echo -e '\nDisabling auto-updates by removing update-notifier-common ...'
sudo apt-get -y purge update-notifier-common

# PURGE all things unneeded?
# Establish apt proxy?
# Install all system updates?

#echo -e '\nInstalling NTP ...'
#sudo apt-get -y install ntp

echo -e '\nInstalling ifupdown as alternative to network-manager ...'
sudo apt-get -y install ifupdown || { echo 'Error installing ifupdown, not continuing with network-manager removal!'; exit; }

echo -e '\nDisabling the graphical network manager ...'
sudo apt-get -y purge network-manager

echo -e '\nAdding default ifupdown config for common network interfaces ...'
echo '
allow-hotplug eth0
iface eth0 inet dhcp
' | sudo tee /etc/network/interfaces.d/eth0
echo '
allow-hotplug eth1
iface eth1 inet dhcp
' | sudo tee /etc/network/interfaces.d/eth1

echo -e '\nEnabling ifupdown-compatible WiFi configuration ...'
echo 'allow-hotplug wlan0
iface wlan0 inet dhcp
$WLAN0_OPTIONS
' | sudo tee /etc/network/interfaces.d/wlan0
sudo timeout -k 12 10 ifup -v wlan0

echo -e '\nRemoving avahi services to avoid unintended network configurations ...'
sudo apt-get -y purge 'avahi-*'

echo -e '\nPurging all packages no longer necessary ...'
sudo apt-get -y autoremove --purge

echo -e '\nCreating dedicated user account ansible1 ...'
sudo useradd -g 1000 -m -s '/bin/bash' -c 'auto-generated for ansible' -G sudo ansible1
sudo usermod -p '\$6\$GixLdPpKTOcuGrkg\$vkrDPdf9yQPbqA3C6eEPtmm9w/NzkCVWLsCRUkMnlGB2IvdFJpIMtJx6fu2NUX52jDIbzbVk/x1ari52TJ0r0.' ansible1
sudo mkdir -p -m 700 ~ansible1/.ssh/
echo '$ANSIBLE_AUTHKEYS' | sudo tee ~ansible1/.ssh/authorized_keys
sudo chmod 644 ~ansible1/.ssh/authorized_keys
sudo chown -R ansible1:utilidata ~ansible1/.ssh/

echo -e '\nEnd of ssh session.'
"

#sudo userdel -r ansible1

echo -e "\nThird ssh session completed.\n\n"


echo -e "\nGathering system information..."

mkdir -p log
ssh -t "${SSH_OPTS[@]}" -p "$PORT" "$TGT" ifconfig | tee -a log/${NEWHOSTNAME}_ifconfig

echo -e "\nCompleted."

#nmap -sn 192.168.11.0/24 | grep "${NEWHOSTNAME}"

echo "==========================="
echo "SSH'ing into $TGT to shut down the unit..."

ssh -t "${SSH_OPTS[@]}" -p "$PORT" "$TGT" -o "PasswordAuthentication no" "

echo -e '\nLogin successful !'

echo -e '\nShutting down the unit ...'
echo -e 'Since this is the first sudo command in this session, sudo should ask for the user password:'

sudo shutdown -h now && exit
" || true

echo -e "\nFourth ssh session completed.\n\n"


echo -e "\nIf applicable, remove the USB connection and reboot the unit."


exit


#!/bin/bash

# Todo:
# add -y to each command
# will network will fall back to ifupdown properly?

# install etckeeper? Where in the flow? (this massive purge script should run without internet connection)

set -e

TGT="${1:-jnx30d5}"

ssh "utilidata@$TGT" mkdir -p deploy/ 

echo "SSH'ing into $TGT to disable automatic update and  remove many unneeded packages..."
ssh -t "utilidata@$TGT" "
if [ ! -e /etc/network/interfaces ]; then
echo 'No /etc/network/interfaces, creating default one to be prepared for network manager removal:'
echo 'allow-hotplug eth0
iface eth0 inet dhcp' | sudo tee /etc/network/interfaces
fi

sudo apt purge update-notifier-common


sudo apt purge ubuntu-desktop
sudo apt purge thunderbird
sudo apt purge unity
sudo apt purge gnome-shell
sudo apt purge ubuntu-wallpapers light-themes chromium-browser libreoffice-*
sudo apt purge gnome-* galculator
sudo apt purge avahi-*
sudo apt purge lxde-*
sudo apt purge kwin-* ubiquity-ubuntu-artwork
sudo apt purge lxsession update-manager
sudo apt purge libgnome*
sudo apt purge indicator*
sudo apt purge desktop-file-utils libmenu-cache-bin lxmenu-data xdg-utils
sudo apt purge mousetweaks obsession libkf5notifications-data
sudo apt purge gir1.2-freedesktop libfile-basedir-perl
sudo apt purge lxterminal
sudo apt purge ffmpeg chromium-codecs-ffmpeg-extra
sudo apt purge libavahi-glib1 libavahi-ui-gtk3-0
sudo apt purge libavcodec57 libavfilter6 libavformat57 libavresample3 libavutil55 libpostproc54 libswresample2 libswscale4
sudo apt purge gstreamer1.0-*
sudo apt purge yelp ubuntu-sounds libgoa-1.0-common libgdm1
sudo apt purge pinentry-gnome3 gcr libgail-common libgail18
sudo apt purge lightdm lightdm-gtk-greeter
sudo apt purge rpcbind
sudo apt purge wpasupplicant
sudo apt purge packagekit
sudo apt purge gir1.2-packagekitglib-1.0 libpackagekit-glib2-18
sudo apt purge dbus-x11 x11-session-utils libx11-doc
sudo apt purge snapd
sudo apt purge samba-libs


sudo apt-get autoremove --purge

"

ssh "utilidata@$TGT" "echo $? > 'deploy/ran_$( basename $0 )'"

touch "log/${TGT}_$( basename $0 )"


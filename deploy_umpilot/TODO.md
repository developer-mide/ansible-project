
## Manual deploy scripts

(the following list was an early planning stage, currenlty not implemented in this repository)

* `deploy20_wifi.sh`      : Needs WiFi module plugged in, brings unit up wirelessly
* `deploy22_microhard.sh` : Configures Microhard router (attached via Ethernet)
* `deploy24_ssdmount.sh`  : Mounts the ssd (tbd: encryption scheme, mount location)
* `deploy30_devcore.sh`   : g++, strace, ...
* `deploy30_devextra.sh`  : jtop, ...


## Thoughts

Can some ansible steps be optional? (and reversable?)

For example, it might be very useful to have the ability to turn a unit into a "dev node" temporarily,
i.e. installing all the packages usually not necessary (strace, jtop, g++, ...), see 'deploy30_devcore.sh' ?

## TODOS

* Check time/install NTP (currently in deploy10, is it also in Ansible?)
* Mount SSD - encrypted (Ansible?)
* Connect & Configure WiFi Module
	* The new "Deploy WiFi" ("usetup") is part of endudai's network
* Connect & Configure Microhard Router (will change how ansible can access unit, ssh can be accessed using an external IP with non-standard port)
* Strip more packages - at least those which run unecessary services (Ansible?)
	* dbus? pulseaudio? ... (should all go away when removing graphical stuff)
	* snapd? samba? ... (to reduce surface area for other tools using these if available?)
* apt-get upgrade - when to run the first time? On network, but after all the stripping?

* activate nvpmodel
* firmware updater for metrology board

* Disabling the USB auto network config? (but we are SSH key only, so no issue here?)
	* what about /dev/ttyACM0 ???

* Further securing but don't know how yet:
	* Disabling USB flashing option? Secure Boot? Encrypting EMMC?


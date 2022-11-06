# utilidata_deploy/

collection of scripts used to configure freshly imaged Jetson systems

## Retrieving files excluded from this repository

scp -P 17422 yourusername@70.142.45.216:/mnt/share/pilot_files/{authorized_keys,xaviernx_list.txt} files/

If necessary, add your local public key to files/authorized_keys
so you can log into the systems you are deploying after disabling SSH password authentication

## Imaging a new Auvidea Jetson system to boot from SSD

1. Connect Power + USB (don't connect network cable yet!)
2. Flash "bootFromExternalStorage" from https://www.jetsonhacks.com/2021/08/25/native-boot-for-jetson-xaviers/
3. power-cycle the device, but it won't come up (some Auvidea magic sauce is missing?)
4. Flash Auvidea's Firmware from https://f000.backblazeb2.com/file/auvidea-download/images/Jetpack_4_6/BSP/Jetpack4.6_Xavier_NX_BSP.tar.gz
5. Remove USB cable, power-cycle device

Use local keyboard&HDMI monitor or /dev/ttyACM0 (e.g. with sudo screen /dev/ttyACM0 115200) to go through the initial setup:
* Time Zone: EST
* User: utilidata (consider using a simple shared standard password, these scripts need it OFTEN, and we will disable remote access anyway)
* Hostname: jnx30dXX (replace XX with the next free sequence number, see xaviernx_list.txt)
* Skip network config

## First-time network connection

* Reboot, connect network cable after reboot, log in via ACM0, locally or check your DHCP server for Mac & IP of the new system
* Recommendation: Add system's name and IP to the /etc/hosts of the system you use for deployment

## SSH access, remove packages for slim image, update & upgrade the system

Change which of the following scripts you run and their order depending on your usecase:

```
deploy_authorized_keys_ssh_config.sh
deploy_aptpurgesforslimimage.sh
deploy_aptupdateupgrade.sh
deploy_devtools1.sh
```

* NOTE: These scripts primary purpose was _reproducability_ of deployment, not (yet) fully automating it.
* These scripts will often ask for sudo passwords on the system being deployed,
and many apt commands still ask for confirmation.

One extra annoying thing is updating docker, it asks whether restarting docker is OK, didn't find a way to automatically say yes here

## The other useful scipts

```
deploy_jetson-io.sh : only needed for old metrology directly connecting to 40-pin header, very manual
deploy_python.sh : the "old" way of getting a common python 3.8 onto the systems, ALSO INSTALLS jetson-stats and numpy

deploy_remove_autoupdate.sh : already part of deploy_aptpurgesforslimimage.sh, but useful if using full image
deploy_restart.sh : issues restart
deploy_shutdown.sh : isseus shutdown, CAREFUL: NEED POWER CYCLE CAPABILITY TO BOOT UP AGAIN
```

## Historic scripts for old SPINX as running on Lake Placid

```
deploy_restart_spinx.sh
deploy_service_spinx.sh
deploy_spinx_calib.sh
deploy_spinx.sh
deploy_supervisor.sh
deploy_test_sgc_live_metrology.sh
```

## tools/

Mix of scripts used for live data plotting and things running on Lake Placid prototypes.
Some of these might be adapted to new SPINX for new Metrology currently under development.



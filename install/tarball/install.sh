#!/bin/bash
#V. Verdon Corp.! 
#Version 20260730
#############################
VERSION=2.1.0-beta3
REP_INS=$(dirname $0)
#Software directory
REP=/usr/lib/network-in

echo "Starting Network-In! $VERSION installation..."
echo

#Script must be executed by root
if [ $(id -u) -ne 0 ]
then 
	echo This installation script requires root user, sorry !
	exit 1
fi

#Dependencies verification stage
##############################################
#exe_name;software_package_name
LISTE_DEP="
sudo;sudo
tclsh;tcl
wish;tk
wmctrl;wmctrl
xwininfo;x11-utils or xwinfo
iptables;iptables or iptables-legacy
xfwm4;xfwm4
Xephyr;xserver-xephyr or xorg-x11-server-Xephyr
xsel;xsel
hsetroot;hsetroot
xhost;xhost or x11-xserver-utils
brctl;bridge-utils
wireshark;wireshark
xdotool;xdotool
evince;evince
"

ARRET=false
IFS=$'\n'
for L in $LISTE_DEP
do
	EXE=$(echo $L| cut -d ';' -f 1)
	PROG=$(echo $L| cut -d ';' -f 2)
	RES=$(which $EXE)
	if [ -z $RES ]
	then
		echo $EXE NOT FOUND. Install $PROG packet to fix this problem
		ARRET=true
	else
		echo $RES found
	fi
done

echo

#Some executables are missing
if $ARRET
then
	echo Network-In installation has stopped. Some softwares are missing...
	exit 2
fi


#Installation stage
##############################################
#Extraction fichiers de l'archive
echo 'Copying files... Please wait...'
tar -xf $REP_INS/network-in.tar -C / --owner root --group root --no-overwrite-dir

#sudo necessite de pouvoir resoudre le nom de la machine
HOSTNAME=$(hostname)
if [ -z "$(grep $HOSTNAME /etc/hosts)" ]
then
  echo "127.0.0.1  $HOSTNAME" >> /etc/hosts
fi

#Capabilities modification for capture by anyone
chmod 0755 $(which dumpcap)
setcap cap_net_raw,cap_net_admin=ep $(which dumpcap)

#Ajout d'entrées dans sudoers
cat <<EOF>> /etc/sudoers

# Network-In! Simulator sudo auth
ALL  ALL=NOPASSWD:$REP/bin/network-in-start
ALL  ALL=NOPASSWD:$REP/bin/network-in-stop
ALL  ALL=NOPASSWD:$REP/bin/conf_nat
ALL  ALL=NOPASSWD:$REP/bin/conf_bridge
ALL  ALL=NOPASSWD:/usr/lib/network-in/bin/conf_capture
ALL  ALL=NOPASSWD:/usr/lib/network-in/bin/set_disks_mtime

EOF
chmod 0440 /etc/sudoers
sudo -v

#Création lien vers libvde
#LIBVDE=$(find /usr/lib -name 'libvdeplug.so.*' -type f 2>/dev/null | sort | tail -n 1)
#ln -s $LIBVDE $(dirname $LIBVDE)/libvdeplug.so 2>/dev/null
#Prise en compte des path lib de /etc/ld.so.conf.d/network-in.conf
ldconfig

#vde_plug must be in executable path for linux.uml lauch
ln -s $REP/vde4networkin/vde_plug /usr/bin

#root devient propriétaire des fichiers
#chown -R root:root $REP
#chown root:root /etc/network-in.cfg
#chown root:root /usr/bin/network-in

# Symlink networkin alternative to launch the simulator
ln -s /usr/bin/network-in /usr/bin/networkin 2> /dev/null

chmod +x $REP/bin/*

echo "Installation completed. Enjoy !"

exit 0

#!/bin/bash
#V. Verdon Corp.! 
#Version 20260408
#############################
REP_INS=$(dirname $0)
#Software directory
REP=/usr/lib/network-in


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
tclsh;tcl
wish;tk
vde_switch;vde2
sudo;sudo
wmctrl;wmctrl
iptables;iptables
xfwm4;xfwm4
Xephyr;xserver-xephyr
xsel;xsel
hsetroot;hsetroot
xterm;xterm
xhost;x11-xserver-utils
bridge-utils;bridge-utils
"

ARRET=false
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

#Some executables are missing
if $ARRET
then
	echo Network-In installation has stopped. Some softwares are missing...
	exit 2
fi

#Installation stage
##############################################
#Extraction fichiers de l'archive
echo
echo 'Copying files... Please wait...'
tar -xf $REP_INS/network-in.tar -C / --owner root --group root --no-overwrite-dir

#sudo necessite de pouvoir resoudre le nom de la machine
HOSTNAME=$(hostname)
if [ -z "$(grep $HOSTNAME /etc/hosts)" ]
then
  echo "127.0.0.1  $HOSTNAME" >> /etc/hosts
fi

#Ajout d'entrées dans sudoers
cat <<EOF>> /etc/sudoers

# Network-In! Simulator sudo auth
ALL  ALL=NOPASSWD:$REP/bin/network-in-start
ALL  ALL=NOPASSWD:$REP/bin/network-in-stop
ALL  ALL=NOPASSWD:$REP/bin/conf_gateway
ALL  ALL=NOPASSWD:$REP/bin/conf_bridge
EOF
chmod 0440 /etc/sudoers
sudo -v

#Création lien vers libvde
LIBVDE=$(find /usr/lib -name 'libvdeplug.so.*' -type f 2>/dev/null | sort | tail -n 1)
ln -s $LIBVDE $(dirname $LIBVDE)/libvdeplug.so 2>/dev/null

#root devient propriétaire des fichiers
#chown -R root:root $REP
#chown root:root /etc/network-in.cfg
#chown root:root /usr/bin/network-in
ln -s /usr/bin/network-in /usr/bin/networkin
chmod +x $REP/bin/*

exit 0

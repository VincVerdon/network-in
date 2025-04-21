#!/bin/bash
#V. Verdon Corp.! 
#Version 20250213
#############################
REP_INS=$(dirname $0)
#Repertoire de l'application
REP=/usr/lib/network-in


#Script must be executed by root
if [ $(id -u) -ne 0 ]
then 
	echo This installation script requires root user, sorry !
	exit 1
fi

#dependencies verification stage
##############################################
#exe_name;software_package_name
LISTE_DEP="
tclsh;tcl
wish;tk
vde_switch;vde2
uml_mconsole;uml-utilities
sudo;sudo
lsof;lsof
wmctrl;wmctrl
xwininfo;x11-utils
iptables;iptables
xfwm4;xfwm4
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


#Modification de la config serveur X pour accepter les connexion TCP
#avec gdm3
if [ -e /etc/gdm3/daemon.conf ]
then
	echo "[security]" >> /etc/gdm3/daemon.conf
	echo "DisallowTCP=false" >> /etc/gdm3/daemon.conf
fi

#avec gdm
if [ -e /etc/gdm/gdm.conf ]
then
	echo "[security]" >> /etc/gdm/gdm.conf
	echo "DisallowTCP=false" >> /etc/gdm/gdm.conf
fi

#avec xdm
if [ -e /etc/X11/xdm/Xservers ]
then
	grep -v "^[^#].*-nolisten tcp" /etc/X11/xdm/Xservers > /etc/X11/xdm/Xservers.new
	grep "^[^#].*-nolisten tcp" /etc/X11/xdm/Xservers | sed "s|-nolisten tcp| |" >> /etc/X11/xdm/Xservers.new
	mv /etc/X11/xdm/Xservers /etc/X11/xdm/Xservers.anc
	mv /etc/X11/xdm/Xservers.new /etc/X11/xdm/Xservers
fi

#avec lightdm
if [ -e /etc/lightdm/lightdm.conf ]
then
		sed -i s/^#xserver-allow-tcp=false$/xserver-allow-tcp=true/ /etc/lightdm/lightdm.conf
fi
#avec lightdm sous Ubuntu
if [ -d /etc/lightdm/lightdm.conf.d/ ]
then
	cat <EOF>> /etc/lightdm/lightdm.conf.d/90-network-in.conf
	[Seat:*]
	xserver-allow-tcp=true
	EOF
fi

#avec gdm3 sous Ubuntu
if [ -e /etc/gdm3/custom.conf ]
then
    sed -i 's/^DisallowTCP=true/DisallowTCP=false/' /etc/gdm3/custom.conf
    sed -i '/\[security\]/a DisallowTCP=false' /etc/gdm3/custom.conf
fi

#root devient propriétaire des fichiers
chown -R root:root $REP
chown root:root /etc/network-in.cfg
chown root:root /usr/bin/network-in
ln -s /usr/bin/network-in /usr/bin/networkin
chmod +x $REP/bin/*

echo 'You must leave your X session and restart X server (or reboot) before using Network-In!'
exit 0

#!/bin/bash
#V. Verdon Corp.! 
#Version 20240922
#############################
REP_INS=$(dirname $0)
#Repertoire de l'application
REP=/usr/lib/network-in


#Script must be executed by root
if [ $(id -u) -ne 0 ]
then 
	echo This uninstallation script requires root user, sorry !
	exit 1
fi

#Suppression of entries in sudoers
sed -i 's/.*Network-In!.*//' /etc/sudoers
sed -i 's/.*network-in.*//' /etc/sudoers
chmod 0440 /etc/sudoers
sudo -v
#rm -f /etc/sudoers.d/network-in

#Modification of X server configuration to reject TCP connexions
#With lightdm
if [ -e /etc/lightdm/lightdm.conf ]
then
	sed -i 's/^xserver-allow-tcp=true$/#xserver-allow-tcp=false/' /etc/lightdm/lightdm.conf
fi

#files suppression
rm /etc/lightdm/lightdm.conf.d/90-network-in.conf
rm -rf $REP
rm -f /etc/network-in.cfg
rm -f /usr/bin/network-in
rm -f /usr/share/applications/network-in.desktop
rm -rf /usr/share/doc/network-in

exit 0

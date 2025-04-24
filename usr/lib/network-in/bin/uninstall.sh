#!/bin/bash
#V. Verdon Corp.! 
#Version 20250425
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

#files suppression
rm -rf $REP
rm -f /etc/network-in.cfg
rm -f /usr/bin/network-in
rm -f /usr/share/applications/network-in.desktop
rm -rf /usr/share/doc/network-in

exit 0

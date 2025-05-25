#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20250522
###################
REP=$(dirname $0)

echo "This script prepare a new image of a standard componant (computer, router,...)"
echo "It will copy and install somes features needed by Network-In! in the image"
echo
echo -n "Press c to continue "
read R
if [ "$R" != "c" ] ; then
  echo "Aborted"
  exit
fi

#Installation paquets pour services et utilisateur
apt install -y termshark bind9 isc-dhcp-server isc-dhcp-relay proftpd-basic openssh-server apache2 frr netsurf-gtk gftp ftp
#Services désactivés par défaut
systemctl disable named.service
systemctl disable isc-dhcp-server.service
systemctl disable isc-dhcp-relay.service
systemctl disable proftpd.service
systemctl disable ssh.service
systemctl disable frr.service
systemctl disable apache2.service

#Répertoire des comptes FTP
mkdir /home/ftp
chgrp users /home/ftp
chmod 770 /home/ftp

Désactivation Selinux
sed -r -i 's/^SELINUX=.+$/SELINUX=disabled/' /etc/selinux/config

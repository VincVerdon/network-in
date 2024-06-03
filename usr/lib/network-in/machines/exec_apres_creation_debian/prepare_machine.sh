#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20240528
###################
REP=$(dirname $0)

echo "This script prepare a new image of computer"
echo "It will copy and install somes features needed by Network-In! in the image"
echo "You must execute this from the new image after having started the virtual computer"
echo "This scripts are made for DEBIAN Linux. It may not work in another Linux system without some adaptation."
echo "To execute this correctly, all the files of this directory must have been copied in the same destination"
echo
echo -n "Press c to continue "
read R
if [ "$R" != "c" ] ; then
  echo "Aborted"
  exit
fi

#Points de montage
mkdir /lib/modules
cat <<EOF> /etc/fstab
#Configuration of system disks for Network-in Simulator
#Do not modify the two following lines !
/dev/ubda / ext4 discard,errors=remount-ro 0 1
/dev/ubdb /lib/modules ext4 defaults 0 0
EOF

#Désactivation SeLinux
sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config

#Paquets nécessaires à Network-in
#xwininfo nécessaire mais on n'installe pas le paquet car trop gros (on installe libxcb-shape0 par contre car il en a besoin) !
apt install -y tclsh wish ipcalc libxcb-shape0 wmctrl

#Installation paquets pour services et utilisateur
apt install -y net-tools dnsutils iptables tcpdump termshark nmap traceroute bind9 isc-dhcp-server proftpd-basic openssh-server apache2  ftp
systemctl disable bind9.service
systemctl disable isc-dhcp-server.service
systemctl disable proftpd.service
systemctl disable ssh.service
systemctl disable apache2.service

#Remplacement du fichier index.html par une version personnalisée
cp $REP/index.html /var/www/html

#Répertoire des comptes FTP
mkdir /home/ftp
chgrp users /home/ftp
chmod 770 /home/ftp

#Ajout des exe spécifiques à network-in
cp -r $REP/networkin-bin /sbin
#Redirection des appels des commandes vers celles du rep networkin-bin
sed -i 's/[^#] *PATH=/PATH=\/sbin\/networkin-bin:/' /etc/profile

#Installation du daemon nid
cp $REP/nid/* /etc/systemd/system
systemctl daemon-reload
systemctl enable nid.service
systemctl enable nid-halt.service
systemctl enable nid-reboot.service

#Affichage dans nano
cat <<EOF>> /etc/bash.bashrc

#Do not remove this !
#Added for Network-in
alias nano='nano -I'
EOF

#Configuration iptables "classique"
update-alternatives --set iptables /usr/sbin/iptables-legacy

#Nettoyage
apt clean
rm -rf /var/log/journal/*
rm -rf /root/*
rm -rf /root/.*
#Vider la conf de resolv.conf et interfaces
history -c

#Configuration capture Termshark
cp -r $REP/.config /root

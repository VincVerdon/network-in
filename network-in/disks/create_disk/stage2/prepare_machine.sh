#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20250106
###################
REP=$(dirname $0)

echo "This script prepare a new image of computer"
echo "It will copy and install somes features needed by Network-In! in the image"
echo "You must execute this from the new image after having started the virtual computer"
echo "This scripts are made for DEBIAN Linux. It may not work in another Linux system without some adaptation."
echo "To execute this correctly, every files of this directory must have been copied in the same destination"
echo
echo WARNING - IP and resover must be configured before execution and cleaned after and connect to NAT router in Simulator
echo WARNING - Imperativly change SeLinux configuration from "permissive" to "disabled" in /etc/Selinux/config
echo
echo -n "Press c to continue "
read R
if [ "$R" != "c" ] ; then
  echo "Aborted"
  exit
fi

#rep de montage pour les échanges avec l'hôte
mkdir /var/networkin

#Points de montage
mkdir /lib/modules
cat <<EOF> /etc/fstab
#Configuration of system disks for Network-in Simulator
#Do not modify the two following lines !
/dev/ubda / ext4 discard,errors=remount-ro 0 1
/dev/ubdb /lib/modules ext4 defaults 0 0
EOF

#Configuration initiale du nom de machine : noname
sed -r -i 's/^127\.0\.0\.1.+localhost/127\.0\.0\.1    localhost    noname/' /etc/hosts
echo noname > /etc/hostname

#Paquets nécessaires à Network-in
#xwininfo nécessaire mais on n'installe pas le paquet car trop gros (on installe libxcb-shape0 par contre car il en a besoin) !
apt install -y tclsh wish ipcalc libxcb-shape0 wmctrl stterm

#Installation paquets pour services et utilisateur
#Besoin d'activer ensuite manuellement l'auto-complétion dans bash.bashrc
apt install -y net-tools dnsutils iptables tcpdump termshark curl nmap traceroute bind9 isc-dhcp-server isc-dhcp-relay proftpd-basic openssh-server apache2 frr ftp  netsurf-gtk gftp man bash-completion
systemctl disable named.service
systemctl disable isc-dhcp-server.service
systemctl disable isc-dhcp-relay.service
systemctl disable proftpd.service
systemctl disable ssh.service
systemctl disable frr.service
systemctl disable apache2.service

apt purge -y xterm

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
#cat <<EOF>> /etc/bash.bashrc
#
#Do not remove this !
#Added for Network-in
#alias nano='nano -I'
#EOF

#Configuration iptables "classique"
update-alternatives --set iptables /usr/sbin/iptables-legacy

#Nettoyage
apt clean
rm -rf /var/log/journal/*
rm -rf /root/*
rm -rf /root/.*
#Vider la conf de resolv.conf et interfaces
rm .bash_history
history -c

#Configuration capture Termshark
cp -r $REP/.config /root
mkdir -p /root/.cache/termshark/pcaps/

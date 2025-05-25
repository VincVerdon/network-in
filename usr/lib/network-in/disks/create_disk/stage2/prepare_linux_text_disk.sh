#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20250524
###################
REP=$(dirname $0)

echo "This script prepare a new image of computer LINUX TEXT"
echo "It is the second part of disk creation"
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
apt install -y tclsh wish libxcb-shape0 wmctrl stterm xsel xdotool x11-utils

#Installation paquets pour services et utilisateur
#Besoin d'activer ensuite manuellement l'auto-complétion dans bash.bashrc
apt install -y net-tools dnsutils iptables tcpdump curl nmap traceroute man netcat-traditional openssh-client bash-completion

apt purge -y xterm

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

#Configuraton journalctl pour limiter la consommation disque
sed -i 's/#SystemMaxUse=/SystemMaxUse=2M/' /etc/systemd/journald.conf


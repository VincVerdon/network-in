#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20250519
###################
REP=$(dirname $0)

echo "This script prepare a new image of computer"
echo "It finalize installation and clean the disk"
echo
echo WARNING - Imperativly change SeLinux configuration from "permissive" to "disabled" in /etc/selinux/config (normally done)
echo WARNING - active bash_completion in /etc/bash.bashrc
echo
echo -n "Press c to continue "
read R
if [ "$R" != "c" ] ; then
  echo "Aborted"
  exit
fi


#Nettoyage
apt clean
rm -rf /var/log/journal/*
rm -rf /root/*
rm -rf /root/.*
#Vider la conf de resolv.conf et interfaces
cat <<EOF> /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback
EOF
echo > /etc/resolv.conf

#Configuration initiale du nom de machine : noname (à refaire ca a été modifié par le simulateur)
sed -r -i 's/^127\.0\.0\.1.+localhost.+$/127\.0\.0\.1    localhost    noname/' /etc/hosts
echo noname > /etc/hostname

#Nettoyage historique des commandes
rm ~/.bash_history

#Configuration capture Termshark
if which termshark &>/dev/null
then
    cp -r $REP/.config /root
    mkdir -p /root/.cache/termshark/pcaps/
fi

history -c

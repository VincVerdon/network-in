#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20250523
###################

DEB_VERSION=bookworm
VERSION=1.02
#IMG=${DEB_VERSION}_${VERSION}.img
IMG=new.img
TAILLE=1536
#TAILLE=1024

echo "This script prepare a new image of computer/router"
echo "It will copy and install somes features needed by Network-In! in the image"
echo "This scripts are made for DEBIAN Linux. It may not work in another Linux system without some adaptation."
echo "Disk size = $TAILLE ; Debian version = $DEB_VERSION"
echo
echo WARNING - This part needs root account
echo
echo -n "Press c to continue "
read R
if [ "$R" != "c" ] ; then
  echo "Aborted"
  exit
fi

dd if=/dev/zero of=$IMG bs=1M count=$TAILLE
mkfs.ext4 $IMG

mount -o loop $IMG /mnt

debootstrap $DEB_VERSION /mnt

cat <<EOF> /mnt/etc/fstab
#Configuration of root disk for Network-in Simulator
/dev/ubda / ext4 discard,errors=remount-ro 0 1
EOF

#Preconfiguration du réseau pour la suite
cat <<EOF> /mnt/etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address 10.0.0.1
netmask 255.255.255.0
gateway 10.0.0.254
EOF
echo nameserver 9.9.9.9 > /mnt/etc/resolv.conf

#Copie des scripts des étapes suivantes dans le disque
cp -a ../stage{2,3,4} /mnt/root/

#Configuration du mot de passe root
chroot /mnt <<END
echo root:root | chpasswd
END

umount /mnt


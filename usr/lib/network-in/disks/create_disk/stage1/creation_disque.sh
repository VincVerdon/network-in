#!/bin/bash
#Network-in!
#Script de preparation d'une image de machine
#V. Verdon
#Version 20241222
###################

DEB_VERSION=bookworm
VERSION=1.01
IMG=${DEB_VERSION}_${VERSION}.img
TAILLE=1536

dd if=/dev/zero of=$IMG bs=1M count=$TAILLE
mkfs.ext4 $IMG

mount -o loop $IMG /mnt

debootstrap $DEB_VERSION /mnt

cat <<EOF> /mnt/etc/fstab
#Configuration of root disk for Network-in Simulator
/dev/ubda / ext4 discard,errors=remount-ro 0 1
EOF

echo noname > /mnt/etc/hostname

#Désactivation SeLinux pour la suite (impossible car fichier créé par la suite)
#sed -i 's/^SELINUX=permissive/SELINUX=disabled/' /mnt/etc/selinux/config

chroot /mnt
echo root:root | chpasswd
exit

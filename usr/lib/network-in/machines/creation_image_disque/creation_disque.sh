#!/bin/bash

DEB_VERSION=bookworm
VERSION=1
IMG=${DEB_VERSION}_${VERSION}.img
TAILLE=1536

dd if=/dev/zero of=$IMG bs=1M count=$TAILLE
mkfs.ext4 $IMG

mount -o loop $IMG /mnt

debootstrap $DEB_VERSION /mnt

cat <<EOF> /mnt/etc/fstab
#Configuration of root disk for Network-in Simulator
/dev/ubd0  ext4  defaults  0  0
EOF

echo noname > /mnt/etc/hostname

chroot /mnt
echo root:root | chpasswd
exit


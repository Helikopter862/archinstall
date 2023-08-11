#!/bin/bash

mkfs.xfs -f /dev/sda2 || exit && mount /dev/sda2 /mnt && mkdir -p /mnt/boot /mnt/media/data
mkfs.fat -F32 /dev/sda1 || exit && mount /dev/sda1 /mnt/boot

pacstrap /mnt base linux-zen linux-zen-headers linux-firmware || exit
timedatectl set-ntp true
genfstab -U /mnt >> /mnt/etc/fstab
curl -L https://raw.githubusercontent.com/Helikopter862/archinstall/main/chroot-script.sh -o /mnt/chroot-script.sh
arch-chroot /mnt sh chroot-script.sh

reboot

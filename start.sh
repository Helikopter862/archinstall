#!/bin/bash

mkfs.xfs -f /dev/nvme0n1p2 || exit && mount /dev/nvme0n1p2 /mnt && mkdir /mnt/boot 
mkfs.fat -F32 /dev/nvme0n1p1 || exit && mount /dev/nvme0n1p1 /mnt/boot
mount --mkdir /dev/sda1 /mnt/media/data || exit

pacstrap /mnt base linux-zen linux-zen-headers linux-firmware || exit
timedatectl set-ntp true
genfstab -U /mnt >> /mnt/etc/fstab
curl -L https://raw.githubusercontent.com/Helikopter862/archinstall/main/chroot-script.sh -o /mnt/chroot-script.sh
arch-chroot /mnt sh chroot-script.sh

reboot

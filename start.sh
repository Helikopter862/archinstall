#!/bin/bash

if [ $rootxfs ]
then
  mkfs.xfs -f $rootxfs || exit && mount $rootxfs /mnt && mkdir /mnt/boot 
else
  echo "Root partition not added."
  exit
fi

if [ $rootbtrfs ]
then
  mkfs.btrfs -f $rootbtrfs || exit && mount $rootbtrfs /mnt && mkdir /mnt/boot 
else
  echo "Root partition not added."
  exit
fi

if [ $boot ]
then
  mkfs.fat -F32 $boot || exit && mount $boot /mnt/boot
else
  echo "Boot partition not added."
  umount /mnt
  exit
fi

pacstrap /mnt base linux-zen linux-zen-headers linux-firmware || exit
timedatectl set-ntp true
genfstab -U /mnt >> /mnt/etc/fstab
curl -L https://raw.githubusercontent.com/Helikopter862/archinstall/main/chroot-script.sh -o /mnt/chroot-script.sh
arch-chroot /mnt sh chroot-script.sh

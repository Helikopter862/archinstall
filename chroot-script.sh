#!bin/sh

if ! [ $timezone ]
then
  timezone="Europe/Warsaw"
fi

ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
sed -i "/^#en_US.UTF-8/ cen_US.UTF-8 UTF-8" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo archlinux >> /etc/hostname
pacman --noconfirm -Sy neovim base-devel git

pacman --noconfirm -S networkmanager
systemctl enable NetworkManager

if [[ $(grep 'AuthenticAMD' </proc/cpuinfo | head -n 1) ]]
then
  cpu=amd
elif [[ $(grep 'GenuineIntel' </proc/cpuinfo | head -n 1) ]]
then
  cpu=intel
fi
if [ $cpu ]
then
  pacman --noconfirm -S $cpu-ucode
fi

bootctl install
mkdir -p /boot/loader/entries /etc/pacman.d/hooks

echo "default  arch.conf 
timeout  4 
console-mode max 
editor  yes" > /boot/loader/loader.conf
 
echo "title  Arch Linux 
linux  /vmlinuz-linux-zen" > /boot/loader/entries/arch.conf
if [ $cpu ]
then
  echo "initrd  /$cpu-ucode.img" >> /boot/loader/entries/arch.conf
fi
echo "initrd  /initramfs-linux-zen.img
options  root=$(cat /etc/fstab | grep 'UUID' | head -n 1 - | awk '{print $1}') rw" >> /boot/loader/entries/arch.conf
 
if [ "$gpu" == "nvidia" ]
then
  echo "options  mitigations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch.conf
else
  echo "options  mitigations=off" >> /boot/loader/entries/arch.conf
fi
 
 
echo "title  Arch Linux Fallback 
linux  /vmlinuz-linux-zen" > /boot/loader/entries/arch-fallback.conf
if [ $cpu ]
then
  echo "initrd  /$cpu-ucode.img" >> /boot/loader/entries/arch-fallback.conf
fi
echo "initrd  /initramfs-linux-zen-fallback.img
options  root=PART$(cat /etc/fstab | grep 'UUID' | head -n 1 - | awk '{print $1}') rw" >> /boot/loader/entries/arch-fallback.conf
 
if [ "$gpu" == "nvidia" ]
then
  echo "options  mitigations=off nvidia-drm.modeset=1" >> /boot/loader/entries/arch-fallback.conf
else
  echo "options  mitigations=off" >> /boot/loader/entries/arch-fallback.conf
fi


echo "[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service" > /etc/pacman.d/hooks/100-systemd-boot.hook

if ! [ $rootpw ]
then
  rootpw="root"
fi
if ! [ $username ]
then
  username="user"
fi
if ! [ $userpw ]
then
  userpw="user"
fi

echo "root:$rootpw" | chpasswd
useradd -mg wheel $username
echo "$username:$userpw" | chpasswd
sed -i "/^# %wheel ALL=(ALL:ALL) ALL/ c%wheel ALL=(ALL:ALL) ALL" /etc/sudoers

sed -i "/^#Color/cColor" /etc/pacman.conf
sed -i "/^#ParallelDownloads/cParallelDownloads = 5" /etc/pacman.conf
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu

pacman --noconfirm -S xorg xorg-xinit noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra pipewire lib32-pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pulsemixer

case $gpu in 
  nvidia)
    pacman -S --noconfirm --needed lib32-libglvnd lib32-nvidia-utils lib32-vulkan-icd-loader libglvnd nvidia-dkms nvidia-settings vulkan-icd-loader
    mkinitcpio -P
    ;;
    
  amd)
    pacman -S --noconfirm --needed xf86-video-amdgpu mesa lib32-mesa lib32-vulkan-icd-loader lib32-vulkan-radeon vulkan-icd-loader vulkan-radeon
    mkinitcpio -P
    ;;
   
  *)
    pacman -S --noconfirm xf86-video-amdgpu xf86-video-intel xf86-video-nouveau
    mkinitcpio -P
    ;;
esac

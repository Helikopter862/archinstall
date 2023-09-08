#!bin/sh

ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc
sed -i "/^#en_US.UTF-8/ cen_US.UTF-8 UTF-8" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo archlinux >> /etc/hostname

pacman --noconfirm --needed -S neovim base-devel git networkmanager intel-ucode
systemctl enable NetworkManager

bootctl install
mkdir -p /boot/loader/entries /etc/pacman.d/hooks

echo "default  arch.conf 
timeout  4 
console-mode max 
editor  yes" > /boot/loader/loader.conf
 
echo "title  Arch Linux 
linux  /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options  root=/dev/nvme0n1p2 rw
options  mitigations=off nvidia-drm.modeset=1" > /boot/loader/entries/arch.conf

echo "title  Arch Linux Fallback 
linux  /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen-fallback.img
options  root=/dev/nvme0n1p2 rw
options. mitigations=off nvidia-drm.modeset=1" > /boot/loader/entries/arch-fallback.conf

echo "[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service" > /etc/pacman.d/hooks/95-systemd-boot.hook

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
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Syu

pacman --noconfirm --needed -S xorg xorg-xinit noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra pipewire lib32-pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pulsemixer lib32-libglvnd lib32-nvidia-utils lib32-vulkan-icd-loader libglvnd nvidia-dkms nvidia-settings vulkan-icd-loader ttf-jetbrains-mono-nerd xclip neofetch htop mpv libxft xterm rofi feh thunar gvfs unzip maim alsa-utils
sudo mkinitcpio -P

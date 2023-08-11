#!bin/sh

ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc
sed -i "/^#en_US.UTF-8/ cen_US.UTF-8 UTF-8" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo archlinux >> /etc/hostname

pacman --noconfirm -Sy neovim base-devel git
pacman --noconfirm -S networkmanager
systemctl enable NetworkManager
pacman --noconfirm -S intel-ucode

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

pacman --noconfirm --needed -S xorg xorg-xinit noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra pipewire lib32-pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pulsemixer lib32-libglvnd lib32-nvidia-utils lib32-vulkan-icd-loader libglvnd nvidia-dkms nvidia-settings vulkan-icd-loader ttf-jetbrains-mono-nerd neofetch htop mpv bspwm sxhkd polybar alacritty rofi feh thunar unzip flameshot
sudo mkinitcpio -P

mkdir -p ~/.config/bspwm/
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
mkdir -p /home/karol/.config/alacritty /home/karol/.config/polybar /home/karol/.config/rofi /home/karol/.config/sxhkd

curl -L "https://raw.githubusercontent.com/Helikopter862/dotfiles/main/.config/alacritty/alacritty.yml" -o /home/karol/.config/alacritty/alacritty.yml
curl -L "https://raw.githubusercontent.com/Helikopter862/dotfiles/main/.config/polybar/config.ini" -o /home/karol/.config/polybar/config.ini
curl -L "https://raw.githubusercontent.com/Helikopter862/dotfiles/main/.config/polybar/launch.sh" -o /home/karol/.config/polybar/launch.sh
curl -L "https://raw.githubusercontent.com/Helikopter862/dotfiles/main/.config/rofi/config.rasi" -o /home/karol/.config/rofi/config.rasi
curl -L "https://raw.githubusercontent.com/Helikopter862/dotfiles/main/sxhkdrc" -o /home/karol/.config/sxhkd/sxhkdrc

echo "#!/bin/sh
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

# gnome
# export XDG_SESSION_TYPE=x11
# export GDK_BACKEND=x11
# exec gnome-session
#
# bspwm

exec bspwm &
bash /home/karol/.config/polybar/launch.sh &
sxhkd -c $HOME/.config/sxhkd/sxhkdrc" > /home/karol/.xinitrc

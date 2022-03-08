#!/bin/sh

loadkeys br-abnt2

cfdisk /dev/sda

mkfs.fat -F32 /dev/sda1
fatlabel /dev/sda1 BOOT
mkfs.btrfs /dev/sda2
btrfs filesystem label /dev/sda2 ROOT

mount /dev/sda2 /mnt
btrfs su cr /mnt/@
umount /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
basestrap /mnt base base-devel openrc elogind-openrc neovim
basestrap /mnt linux linux-firmware
fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt

ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
hwclock --systohc
echo "$(cat /etc/locale.gen | sed -e 's/#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/')" > /etc/locale.gen

echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf

echo "$(cat /etc/conf.d/keymaps | sed -e 's/keymap=.*/keymap="br-abnt2"/')" > /etc/conf.d/keymaps

echo "KEYMAP=br" >> /etc/vconsole.conf

pacman -S grub os-prober efibootmgr git libressl xdg-utils alsa-utils linux-headers neovim
echo "$(cat /etc/mkinitcpio.conf | sed -e 's/MODULES=()/MODULES=(btrfs)/')" > /etc/mkinitcpio.conf
mkinitcpio -p linux

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

useradd -mG sudo,wheel ralsei
passwd ralsei
passwd

echo "artix" >> /etc/hostname
echo "# Hostname fallback if /etc/hostname does not exist" > /etc/conf.d/hostname
echo "hostname=artix" >> /etc/conf.d/hostname
echo "127.0.0.1        localhost" >> /etc/hosts
echo "::1              localhost" >> /etc/hosts
echo "127.0.1.1        artix.localdomain  myhostname" >> etc/hosts

pacman -S dhcpcd connman-openrc
rc-update add connmand

exit
umount -R /mnt
reboot

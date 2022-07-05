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

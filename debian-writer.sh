#!/usr/bin/env bash
# Bash3 Debian Writer. Copyright 2020, NXP Semiconductors.
# Diego Dorta <diego.dorta@nxp.com>

set -e

function create_empty() {
    dd if=/dev/zero of=disk.img bs=1024 count=1048576 status=none && sync && sleep 1
}

function mount_vdevice() {
    losetup /dev/loop0 disk.img && sleep 1
}

function umount_vdevice() {
    losetup -d /dev/loop0 && sleep 1
}

function create_partition() {
    (
        echo mklabel msdos
        echo mkpart primary fat32 10MiB 100MiB
        echo mkpart primary ext4 100MiB -1
        echo quit
    ) | parted /dev/loop0 && sleep 1
}

function format_vdevice() {
    mkfs -t vfat -n boot /dev/loop0p1 && sleep 1
    mkfs -t ext4 -L root /dev/loop0p2 && sleep 1
}

function write_stage0() {
    dd if=stage0/flash.bin of=/dev/loop0 bs=1K seek=32 status=none && sync && sleep 1
}

function write_stage1() {
    mount /dev/loop0p1 /mnt
    cp stage1/kernel/* /mnt
    umount /mnt    
}

function debian_first_stage() {
    mount /dev/loop0p2 /mnt
    debootstrap --foreign --arch arm64 buster /mnt http://ftp.us.debian.org/debian
    #rsync -avHP stage1/lib /mnt
    umount /mnt
}

function debian_second_stage() {
    mount /dev/loop0p2 /mnt
    #(
    #    echo ./debootstrap/debootstrap --second-stage
    #    echo "root" > /etc/hostname
    #) | chroot /mnt && exit
    chroot /mnt ./debootstrap/debootstrap --second-stage
    chroot /mnt /bin/bash -c "echo root > /etc/hostname"
    chroot /mnt /bin/bash -c "echo ttyLP0 >> /etc/securetty"
    chroot /mnt /bin/bash -c "echo 'auto eth0' >> /etc/network/interfaces"
    chroot /mnt /bin/bash -c "echo 'iface eth0 inet dhcp' >> /etc/network/interfaces"
    #chroot /mnt /bin/bash -c
    #chroot /mnt /bin/bash -c
    
    umount /mnt 
}

function run() {
    create_empty
    mount_vdevice
    create_partition
    format_vdevice
    write_stage0
    write_stage1
    debian_first_stage
    debian_second_stage
    umount_vdevice
}

main() {
    echo "Debian Writer -- Tool for Generating Images for i.MX8 Boards (Version 1.0.0)"
    if [ "$EUID" -ne 0 ]
      then echo "Please run as root"
      exit
    fi
    run
    echo "Finish"
}

# Starts Debian Writer
main




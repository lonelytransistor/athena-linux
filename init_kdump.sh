#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
export PATH=/bin/

# From gentoo wiki
cmdline() {
    local value
    value=" $(cat /proc/cmdline) "
    value="${value##* ${1}=}"
    value="${value%% *}"
    [ "${value}" != "" ] && echo "${value}"
}

# Create mountpoints.
mkdir -p /proc /sys /dev /mnt/ro /mnt/rw /mnt/root

# Mount the /proc and /sys filesystems.
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Perform sanity check. If failed uboot will start normal kernel next.
test -e $(cmdline root_ro) || exit 1
test -e $(cmdline root_rw) || exit 1

# Prepare read-only root.
mount -o ro $(cmdline root_ro) /mnt/ro

# Prepare read-write root.
mount -o rw $(cmdline root_rw) /mnt/rw

# Prepare overlay root.
mount -t overlay -o lowerdir=/mnt/ro,upperdir=/mnt/rw/.rootdir,workdir=/mnt/rw/.workdir rootfs /mnt/root

# Dump kernel log into the read-write root.
dump_name="$(date +%H.%M_%d.%m.%Y)"
mkdir -p /mnt/root/var/log/kdump
dmesg > /mnt/root/var/log/kdump/${dump_name}.log
vmcore-dmesg > /mnt/root/var/log/kdump/${dump_name}.vmcore.log
rm -f /mnt/root/var/log/kdump/last_log_name
ln -s ${dump_name}.log /mnt/root/var/log/kdump/last_log
echo ${dump_name} > /mnt/root/var/log/kdump/last_log_name

# Clean up.
umount /mnt/root
umount /mnt/ro
umount /mnt/rw
umount /proc
umount /sys
umount /dev

# Reboot the system
reboot

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
mkdir -p /proc /sys /dev /mnt/rw

# Mount the /proc and /sys filesystems.
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Perform sanity check. If failed uboot will start normal kernel next.
test -e "$(cmdline root_rw)" && mnt_dev="$(cmdline root_rw)" || mnt_dev="/dev/mmcblk2p4"
test -e "$(cmdline root_rw)" || reboot

# Prepare read-write root.
mount -o rw ${mnt_dev} /mnt/rw

# Dump kernel log into the read-write root.
dump_name="$(date +%H.%M_%d.%m.%Y)"
mkdir -p /mnt/rw/.rootdir/var/log/kdump
dmesg > /mnt/rw/.rootdir/var/log/kdump/${dump_name}.log
vmcore-dmesg > /mnt/rw/.rootdir/var/log/kdump/${dump_name}.vmcore.log
rm -f /mnt/rw/.rootdir/var/log/kdump/last_log_name
ln -s ${dump_name}.log /mnt/rw/.rootdir/var/log/kdump/last_log
echo ${dump_name} > /mnt/rw/.rootdir/var/log/kdump/last_log_name

# Clean up.
umount /mnt/rw
umount /proc
umount /sys
umount /dev

# Reboot the system
reboot

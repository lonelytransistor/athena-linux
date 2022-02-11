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
mkdir -p /mnt/rw/root
mkdir -p /mnt/rw/.rootdir
mkdir -p /mnt/rw/.workdir

# Remove all older overrides on overlay root. This helps with soft bricks caused by a firmware update.
(
cd /mnt/ro
for fname in $(find); do
    if [ 0$(stat --printf=%Y /mnt/ro/${fname}) == 0$(stat --printf=%Y /mnt/rw/.rootdir/${fname}) ]; then
        rm /mnt/rw/.rootdir/${fname}
    do
done
)

# Prepare overlay root.
mount -t overlay -o lowerdir=/mnt/ro,upperdir=/mnt/rw/.rootdir,workdir=/mnt/rw/.workdir rootfs /mnt/root
if [ ! -e /mnt/root/etc/fstab ]; then
    mkdir -p /mnt/root/etc
    sed -r '\~^/dev/mmcblk[0-9]+p[0-9]+\s+/home\s~d' /mnt/ro/etc/fstab > /mnt/root/etc/fstab
fi
mkdir -p /mnt/root/home/root
mount --rbind /mnt/rw/root /mnt/root/home/root

# Load dump kernel.
kexec --type zImage --dtb=/mnt/root/boot/kdump.dtb -p /mnt/root/boot/zImage_kdump --append="root_ro=$(cmdline root_ro) root_rw=$(cmdline root_rw) single maxcpus=1 reset_devices"

# Clean up.
umount /proc
umount /sys
umount /dev

# Boot the real thing.
exec switch_root /mnt/root /sbin/init

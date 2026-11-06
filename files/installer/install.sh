#!/bin/sh

. /lib/functions.sh
. /lib/upgrade/nand.sh

sleep 1

echo
echo "OpenWrt UBI installer"
echo

echo "Please upload /tmp/Factory.bin (2048KB) and /tmp/stock-factory.bin (512KB)"
echo "So that it can generate ubi_factory.bin"

if [ ! -s "/tmp/Factory.bin" ] || [ ! -s "/tmp/stock-factory.bin" ]; then
	echo "Missing files. Please upload Factory.bin & stock-factory.bin."
	exit 1
fi

PRELOADER="/installer/mt7981_qihoo_360t7-ubi-preloader_Yuzhii0718.bin"
FIP="/installer/mt7981_qihoo_360t7-ubi-bl31-uboot_Yuzhii0718.fip"

if [ ! -s "$PRELOADER" ] || [ ! -s "$FIP" ]; then
	echo "Missing files. Aborting."
	exit 1
fi

ubi_mknod() {
	local dev="$1"
	dev="${dev##*/}"
	[ -e "/sys/class/ubi/$dev/uevent" ] || return 2
	. "/sys/class/ubi/$dev/uevent"
	mknod "/dev/$dev" c $MAJOR $MINOR
}

echo "Generate empty ubi_factory.bin"
dd if=/dev/zero bs=$((0x8000)) count=1 | tr '\000' '\377' > /tmp/ubi_factory.bin
echo "Copy EEPROM (0x1000) to ubi_factory.bin"
dd if=/tmp/Factory.bin bs=1 count=$((0x1000)) of=/tmp/ubi_factory.bin conv=notrunc
echo "Extract LanMAC to /tmp/mac"
cat /tmp/stock-factory.bin | grep lanMac | sed 's/lanMac=\|://g' > /tmp/mac
echo "Write MAC to ubi_factory.bin"
printf "$(cat /tmp/mac | sed 's/../\\x&/g')" >> /tmp/ubi_factory.bin

echo "Redundantly write bl2"
insmod mtd-rw i_want_a_brick=1
mtd unlock bl2
mtddev="/dev/mtd$(find_mtd_index "bl2")"
mtd -p 0x0 write "$PRELOADER" "$mtddev"
sleep 1
mtd -p 0x80000 write "$PRELOADER" "$mtddev"

mtddev="/dev/mtd$(find_mtd_index "ubi")"
[ -n "$(find_mtd_index "ubi")" ] || mtddev="/dev/mtd1"
echo "Delete ubi0"
[ -e /sys/class/ubi/ubi0 ] && ubidetach -p "$mtddev"
echo "Format ubi"
ubiformat -y "$mtddev"
sleep 1
echo "Attach ubi"
ubiattach -p "$mtddev"
sync
sleep 1
[ -e /dev/ubi0 ] || ubi_mknod ubi0
echo "Create FIP volume (2MiB)"
ubimkvol /dev/ubi0 -n 0 -t static -s 2MiB -N fip
ubi_mknod ubi0_0
echo "Write FIP"
ubiupdatevol /dev/ubi0_0 "$FIP"
sleep 1
echo "Create factory volume"
ubimkvol /dev/ubi0 -n 1 -t static -s 0x10000 -N factory
ubi_mknod ubi0_1
echo "Write ubi_factory.bin"
ubiupdatevol /dev/ubi0_1 "/tmp/ubi_factory.bin"
sleep 1
echo "Create ubootenv volume"
ubimkvol /dev/ubi0 -n 2 -s 0x1f000 -N ubootenv
ubimkvol /dev/ubi0 -n 3 -s 0x1f000 -N ubootenv2
sync

echo "Please check the UBI volume"
ubinfo -a
echo "Please upload ubi-squashfs-sysupgrade.itb in LuCI"
echo "Do NOT keep settings"

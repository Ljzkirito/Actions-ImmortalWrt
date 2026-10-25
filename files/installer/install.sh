#!/bin/sh

. /lib/functions.sh
. /lib/upgrade/nand.sh

sleep 1

echo
echo OpenWrt UBI installer
echo

echo Please upload /tmp/Factory.bin and /tmp/stock-factory.bin
echo So that we can generate ubi_factory.bin

if [ ! -s "/tmp/Factory.bin" ] || [ ! -s "/tmp/stock-factory.bin" ]; then
	echo "Missing files. Aborting."
	exit 1
fi

ubi_mknod() {
	local dev="$1"
	dev="${dev##*/}"
	[ -e "/sys/class/ubi/$dev/uevent" ] || return 2
	source "/sys/class/ubi/$dev/uevent"
	mknod "/dev/$dev" c $MAJOR $MINOR
}

dd if=/dev/zero bs=$((0x8000)) count=1 | tr '\000' '\377' > /tmp/ubi_factory.bin
dd if=/tmp/Factory.bin bs=1 count=$((0x1000)) of=/tmp/ubi_factory.bin conv=notrunc
cat /tmp/stock-factory.bin | grep lanMac | sed 's/lanMac=\|://g' > /tmp/mac
printf "$(cat /tmp/mac | sed 's/../\\x&/g')" >> /tmp/ubi_factory.bin

#echo "redundantly write bl2"
insmod mtd-rw i_want_a_brick=1
mtd unlock bl2
mtd -p 0x0 write "/installer/preloader.bin" /dev/mtd0
sleep 1
mtd -p 0x80000 write "/installer/preloader.bin" /dev/mtd0

[ -e /sys/class/ubi/ubi0 ] && ubidetach -p /dev/mtd1
ubiformat -y /dev/mtd1
sleep 1
ubiattach -p /dev/mtd1
sync
sleep 1
[ -e /dev/ubi0 ] || ubi_mknod ubi0
ubimkvol /dev/ubi0 -n 0 -t static -s 2MiB -N fip
ubi_mknod ubi0_0
ubiupdatevol /dev/ubi0_0 "/installer/bl31-uboot.fip"
sleep 1
ubimkvol /dev/ubi0 -n 1 -t static -s 0x10000 -N factory
ubi_mknod ubi0_1
ubiupdatevol /dev/ubi0_1 "/tmp/ubi_factory.bin"
sleep 1
ubimkvol /dev/ubi0 -n 2 -s 0x1f000 -N ubootenv
ubimkvol /dev/ubi0 -n 3 -s 0x1f000 -N ubootenv2
sync

echo Please check the UBI volume
ubinfo -a

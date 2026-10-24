#!/bin/sh

. /lib/functions.sh
. /lib/upgrade/nand.sh

sleep 1

echo
echo OpenWrt UBI installer
echo

INSTALLER_DIR="/installer"
PRELOADER="$INSTALLER_DIR/openwrt-mediatek-filogic-qihoo_360t7-ubi-preloader.bin"
FIP="$INSTALLER_DIR/openwrt-mediatek-filogic-qihoo_360t7-ubi-bl31-uboot.fip"
RECOVERY="$(ls -1 $INSTALLER_DIR/openwrt-mediatek-filogic-qihoo_360t7-ubi-initramfs-recovery.itb)"
HAS_ENV=1
HAS_FIP=1
HAS_FACTORY=1

if [ ! -s "$PRELOADER" ] || [ ! -s "$FIP" ] || [ ! -s "$RECOVERY" ]; then
	trigger_crash "Missing files. Aborting."
fi

ubi_mknod() {
	local dev="$1"
	dev="${dev##*/}"
	[ -e "/sys/class/ubi/$dev/uevent" ] || return 2
	source "/sys/class/ubi/$dev/uevent"
	mknod "/dev/$dev" c $MAJOR $MINOR
}

install_get_factory() {
	local mtddev="$1"
	local ebs=$(cat /sys/class/mtd/$(basename $mtddev)/erasesize)
	local assertm="$3"
	local init_off="$2"
	local off=$init_off
	local skip="$((init_off / ebs))"
	local found

	while [ $((off)) -lt $((init_off + 4 * ebs)) ]; do
		magic="$(hexdump -v -s $off -n 2 -e '"%02x"' $1)"
		if [ "$magic" = "$assertm" ]; then
			found=1
			break
		fi
		off=$((off + ebs))
		skip=$((skip + 1))
	done

	if [ "$found" != "1" ]; then
		echo "factory partition not found on raw flash offset"
		return 1
	fi

	echo -n "found factory partition at offset $(printf %08x $((off)))"

	dd if=$mtddev bs=$ebs skip=$skip count=1 of=/tmp/Factory.bin
}

install_get_macblock() {
	local mtddev="$1"
	local ebs=$(cat /sys/class/mtd/$(basename $mtddev)/erasesize)
	local assertm="$3"
	local init_off="$2"
	local off=$init_off
	local skip="$((init_off / ebs))"
	local found

	while [ $((off)) -lt $((init_off + 4 * ebs)) ]; do
		magic="$(hexdump -v -s $off -n 2 -e '"%02x"' $1)"
		if [ "$magic" = "$assertm" ]; then
			found=1
			break
		fi
		off=$((off + ebs))
		skip=$((skip + 1))
	done

	if [ "$found" != "1" ]; then
		echo "MAC partition not found on raw flash offset"
		return 1
	fi

	echo -n "Found MAC partition at offset $(printf %08x $((off)))"

	dd if=$mtddev bs=$ebs skip=$skip count=1 of=/tmp/factory.bin
}

install_prepare_ubi() {
	mtddev=$1
	[ -e /sys/class/ubi/ubi0 ] && ubidetach -p $mtddev
	ubiformat -y $mtddev
	sleep 1
	ubiattach -p $mtddev
	sync
	sleep 1
	[ -e /dev/ubi0 ] || ubi_mknod ubi0
	[ "$HAS_FIP" = "1" ] && \
		ubimkvol /dev/ubi0 -n 0 -t static -s 1MiB -N fip && \
		ubi_mknod ubi0_0 && \
		ubiupdatevol /dev/ubi0_0 "$FIP"
	[ "$HAS_FACTORY" = "1" ] && \
		ubimkvol /dev/ubi0 -n 1 -t static -s 0x10000 -N factory && \
		ubi_mknod ubi0_1 && \
		ubiupdatevol /dev/ubi0_1 "/tmp/ubi_factory.bin"
	[ "$HAS_ENV" = "1" ] && \
		ubimkvol /dev/ubi0 -n 2 -s 0x1f000 -N ubootenv && \
		ubimkvol /dev/ubi0 -n 3 -s 0x1f000 -N ubootenv2
}

# extract wifi eeprom from Factory MTD partition
install_get_factory  /dev/mtd1 0x80000   "7981" || \
	trigger_crash "Cannot find Wi-Fi EEPROM data"
install_get_macblock /dev/mtd1 0x7180000 "7768" || \
	trigger_crash "Cannot find MAC"

dd if=/dev/zero bs=$((0x8000)) count=1 | tr '\000' '\377' > \
	/tmp/ubi_factory.bin
dd if=/tmp/Factory.bin bs=1 count=$((0x1000)) of=/tmp/ubi_factory.bin conv=notrunc
cat /tmp/factory.bin | grep lanMac | sed 's/lanMac=\|://g' > /tmp/mac
printf "$(cat /tmp/mac | sed 's/../\\x&/g')" >> /tmp/ubi_factory.bin

#echo "redundantly write bl2"
insmod mtd-rw i_want_a_brick=1
mtd unlock bl2
for bl2start in 0x0 0x80000; do
	mtd -p $bl2start write $PRELOADER /dev/mtd0
done

install_prepare_ubi /dev/mtd$(find_mtd_index "ubi")

sync

#echo "write recovery ubi volume"
#RECOVERY_SIZE=$(cat $RECOVERY | wc -c)
#ubimkvol /dev/ubi0 -n 4 -s $RECOVERY_SIZE -N recovery
#ubi_mknod ubi0_4
#ubiupdatevol /dev/ubi0_4 $RECOVERY
#ubimkvol /dev/ubi0 -n 5 -s 0x1f000 -N fit

sleep 5

#reboot -f

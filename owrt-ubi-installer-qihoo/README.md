mediatek: add support for Qihoo 360T7 (UBI layout)
This commit adds support for Qihoo 360T7 (UBI layout).

Aims
----
1. +20 MB additional free space for the packages
2. More reliable storage for the factory and fip partitions (in UBI)

Install (from non-UBI OpenWrt)
------------------------------
1. Navigate http://192.168.1.1/ and download mtd backups
2. Upgrade OpenWrt with installer initramfs image (force upgrade, don't
   keep settings). Wait until OpenWrt reboots and until installer:
   - Prepare new factory partition
   - Format new ubi
   - Make ubi volumes
   - Write new fip and bl2
3. Navigate http://192.168.1.1/ and Upgrade with OpenWrt 'sysupgrade.bin'
   image (don't keep settings)

Installer
---------
Based on OpenWrt UBI Installer Image Generator for Linksys E8450 and
Belkin RT3200
Link: https://github.com/dangowrt/owrt-ubi-installer

Ready installer image
Link: https://github.com/csharper2005/owrt-ubi-installer/tree/qihoo/bin

Installer script
Link: https://github.com/csharper2005/owrt-ubi-installer/blob/qihoo/files/
installer/install.sh

Committing to the parent Daniel's repository is not yet possible because
there are no official images and imagebuilder for Qihoo 360T7 (UBI) yet.

Signed-off-by: Mikhail Zhilkin <csharper2005@gmail.com>
Link: #22797
Signed-off-by: Hauke Mehrtens <hauke@hauke-m.de>
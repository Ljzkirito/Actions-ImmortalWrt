#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

echo "src-git customsd https://github.com/Ljzkirito/smartdns-openwrt.git;Release46-conf" >> "feeds.conf.default"

# 取消Dnsmasq缓存，由smartdns负责。不修改ttl
sed -i 's/cachesize\t8000/cachesize\t0/g' package/network/services/dnsmasq/files/dhcp.conf
sed -i 's/mini_ttl\t3600/mini_ttl\t0/g' package/network/services/dnsmasq/files/dhcp.conf

# Remove 6in4
sed -i 's/ +6in4//g' package/emortal/ipv6-helper/Makefile
sed -i '/hotplug.d/d' package/emortal/ipv6-helper/Makefile
rm -fv package/emortal/ipv6-helper/files/60-6in4

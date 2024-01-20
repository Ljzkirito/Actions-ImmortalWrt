#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# golang 1.21.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang

# remove v2ray-geodata package from feeds (openwrt-22.03 & master)
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/Ljzkirito/v2ray-geodata feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
find ./ | grep Makefile | grep luci-app-mosdns | xargs rm -f
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# Replace luci-app-ssr-plus & Depends
git clone --depth=1 -b master https://github.com/fw876/helloworld
Replace_package="xray-core xray-plugin v2ray-core v2ray-plugin hysteria ipt2socks microsocks redsocks2 shadowsocks-rust chinadns-ng dns2socks dns2tcp naiveproxy shadowsocksr-libev simple-obfs tcping tuic-client"
for a in ${Replace_package}
do
	echo "Replace_package=$a"
 	rm -rf feeds/packages/net/"$a"
	cp -r helloworld/"$a" feeds/packages/net
done
rm -rf feeds/luci/applications/luci-app-ssr-plus
cp -r helloworld/luci-app-ssr-plus feeds/luci/applications
cp -r helloworld/shadow-tls package
rm -rf helloworld

sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# Remove upx commands
#makefile_file="$({ find package|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
#for a in ${makefile_file}
#do
#	[ -n "$(grep "upx" "$a")" ] && sed -i "/upx/d" "$a"
#done

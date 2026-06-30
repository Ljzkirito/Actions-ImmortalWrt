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

# OpenWrt golang latest version
rm -rfv feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# remove v2ray-geodata package from feeds (openwrt-22.03 & master)
rm -rfv feeds/packages/net/v2ray-geodata
rm -rfv feeds/packages/net/mosdns
find ./ | grep Makefile | grep luci-app-mosdns | xargs rm -fv
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# Replace Smartdns
rm -rfv feeds/luci/applications/luci-app-smartdns
rm -rfv feeds/packages/net/smartdns
git clone --depth=1 -b PikuZheng https://github.com/Ljzkirito/smartdns-openwrt temp-smartdns
mv -fv temp-smartdns/luci-app-smartdns feeds/luci/applications/
mv -fv temp-smartdns/smartdns feeds/packages/net/
rm -rf temp-smartdns

# Replace luci-app-ssr-plus & Depends
Replace_package="xray-core xray-plugin v2ray-core v2ray-plugin hysteria ipt2socks microsocks redsocks2 chinadns-ng dns2socks dns2tcp dnsproxy naiveproxy simple-obfs tcping tuic-client luci-app-ssr-plus lua-neturl gn trojan"
./scripts/feeds uninstall ${Replace_package}
./scripts/feeds install -f -p helloworld ${Replace_package}

# Replace shadowsocks-rust
rm -fv feeds/packages/net/shadowsocks-rust/Makefile
curl -L https://github.com/sbwml/openwrt_helloworld/raw/refs/heads/v5/shadowsocks-rust/Makefile -o feeds/packages/net/shadowsocks-rust/Makefile

# Replace adguardhome
#rm -rfv feeds/packages/net/adguardhome
#git clone https://github.com/Ljzkirito/adguardhome-openwrt feeds/packages/net/adguardhome

# Replace luci-theme-argon
rm -rfv feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon
git -C feeds/luci/themes/luci-theme-argon checkout 1991a8e29ef6a086fb566517675edc85b1be629a

# Replace natmap
rm -rfv feeds/packages/net/natmap
git clone --depth 1 https://github.com/muink/openwrt-natmapt.git package/natmapt
git clone --depth 1 https://github.com/muink/openwrt-stuntman.git package/stuntman
git clone --depth 1 https://github.com/muink/luci-app-natmapt.git package/luci-app-natmapt

# Remove dns2socks-rust & v2raya
rm -rfv feeds/helloworld/dns2socks-rust
rm -rfv feeds/helloworld/v2raya

sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

#git clone --depth=1 -b master https://github.com/fw876/helloworld
#Replace_package="xray-core xray-plugin v2ray-core v2ray-plugin hysteria ipt2socks microsocks redsocks2 chinadns-ng dns2socks dns2tcp naiveproxy simple-obfs tcping tuic-client"
#for a in ${Replace_package}
#do
#	echo "Replace_package=$a"
# 	rm -rfv feeds/packages/net/"$a"
#	cp -rv helloworld/"$a" feeds/packages/net
#done
# sed -i 's/ +libopenssl-legacy//g' feeds/packages/net/shadowsocksr-libev/Makefile
#rm -rfv feeds/luci/applications/luci-app-ssr-plus
#cp -rv helloworld/luci-app-ssr-plus feeds/luci/applications
#cp -rv helloworld/shadow-tls package
#rm -rfv helloworld
# Remove upx commands
#makefile_file="$({ find package|grep Makefile |sed "/Makefile./d"; } 2>"/dev/null")"
#for a in ${makefile_file}
#do
#	[ -n "$(grep "upx" "$a")" ] && sed -i "/upx/d" "$a"
#done

#https://github.com/immortalwrt/packages/issues/1607
#sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile
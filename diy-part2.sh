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
git clone https://github.com/sbwml/v2ray-geodata feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
find ./ | grep Makefile | grep luci-app-mosdns | xargs rm -f
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# Xray 1.8.4 or latest version
rm -rf feeds/packages/net/xray-core/*
wget -P feeds/packages/net/xray-core https://raw.githubusercontent.com/fw876/helloworld/main/xray-core/Makefile
rm -rf feeds/packages/net/xray-plugin/*
wget -P feeds/packages/net/xray-plugin https://raw.githubusercontent.com/fw876/helloworld/main/xray-plugin/Makefile

# v2ray latest version
rm -rf feeds/packages/net/v2ray-core/*
wget -P feeds/packages/net/v2ray-core https://raw.githubusercontent.com/fw876/helloworld/main/v2ray-core/Makefile
rm -rf feeds/packages/net/v2ray-plugin/*
wget -P feeds/packages/net/v2ray-plugin https://raw.githubusercontent.com/fw876/helloworld/main/v2ray-plugin/Makefile

# Update luci-app-ssr-plus & Depends
rm -rf feeds/luci/applications/luci-app-ssr-plus
git clone --depth=1 -b main https://github.com/fw876/helloworld
cp -rf helloworld/luci-app-ssr-plus feeds/luci/applications
rm -rf helloworld
# Update hysteria 2.x & shadow-tls
rm -rf feeds/packages/net/hysteria/*
wget -P feeds/packages/net/hysteria https://raw.githubusercontent.com/fw876/helloworld/main/hysteria/Makefile
wget -P package/shadow-tls https://raw.githubusercontent.com/fw876/helloworld/main/shadow-tls/Makefile

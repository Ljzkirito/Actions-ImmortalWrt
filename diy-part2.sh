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
rm -rf feeds/packages/net/xray-core
svn co https://github.com/fw876/helloworld/branches/main/xray-core feeds/packages/net/xray-core
rm -rf feeds/packages/net/xray-plugin
svn co https://github.com/fw876/helloworld/branches/main/xray-plugin feeds/packages/net/xray-plugin

# v2ray latest version
rm -rf feeds/packages/net/v2ray-core
svn co https://github.com/fw876/helloworld/branches/main/v2ray-core feeds/packages/net/v2ray-core
rm -rf feeds/packages/net/v2ray-plugin
svn co https://github.com/fw876/helloworld/branches/main/v2ray-plugin feeds/packages/net/v2ray-plugin

# Update luci-app-ssr-plus & Depends
rm -rf feeds/luci/applications/luci-app-ssr-plus
svn co https://github.com/fw876/helloworld/branches/main/luci-app-ssr-plus feeds/luci/applications/luci-app-ssr-plus
rm -rf feeds/packages/net/hysteria
svn co https://github.com/fw876/helloworld/branches/main/hysteria feeds/packages/net/hysteria
svn co https://github.com/fw876/helloworld/branches/main/shadow-tls package/shadow-tls

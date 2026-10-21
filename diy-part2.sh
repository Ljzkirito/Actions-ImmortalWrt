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

# Replace Smartdns
rm -rfv feeds/luci/applications/luci-app-smartdns
rm -rfv feeds/packages/net/smartdns
git clone --depth=1 -b PikuZheng https://github.com/Ljzkirito/smartdns-openwrt temp-smartdns
mv -fv temp-smartdns/luci-app-smartdns feeds/luci/applications/
mv -fv temp-smartdns/smartdns feeds/packages/net/
rm -rf temp-smartdns

# Replace luci-theme-argon
rm -rfv feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon

# Remove luci-app-argon-config if exists
if [ -d feeds/luci/applications/luci-app-argon-config ]; then
  echo "Found luci-app-argon-config, removing ..."
  rm -rfv feeds/luci/applications/luci-app-argon-config
else
  echo "luci-app-argon-config not found, skip"
fi

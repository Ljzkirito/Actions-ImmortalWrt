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

# 取消Dnsmasq缓存，由smartdns负责。不修改ttl
#sed -i 's/cachesize\t8000/cachesize\t0/g' package/network/services/dnsmasq/files/dhcp.conf
#sed -i 's/mini_ttl\t3600/mini_ttl\t0/g' package/network/services/dnsmasq/files/dhcp.conf

# Remove 6in4
sed -i 's/ +6in4//g' package/emortal/ipv6-helper/Makefile
sed -i '/hotplug.d/d' package/emortal/ipv6-helper/Makefile
rm -fv package/emortal/ipv6-helper/files/60-6in4

# 关闭 LAN 的 DHCPv6（保持 RA 为 server，仅用 SLAAC），并去掉 RA 的
# managed-config（M）与 other-config（O）标志；odhcpd.defaults 首次启动时
# 生成 /etc/config/dhcp
ODHCPD_DEFAULTS=package/network/services/odhcpd/files/odhcpd.defaults
sed -i -E 's|^(set dhcp\.lan\.dhcpv6=).*|\1disabled|' "$ODHCPD_DEFAULTS"
sed -i '/^add_list dhcp\.lan\.ra_flags=/d' "$ODHCPD_DEFAULTS"

grep -qx 'set dhcp.lan.dhcpv6=disabled' "$ODHCPD_DEFAULTS" || {
  echo "错误：未能将 $ODHCPD_DEFAULTS 中的 dhcp.lan.dhcpv6 设为 disabled" >&2
  exit 1
}
if grep -q '^add_list dhcp\.lan\.ra_flags=' "$ODHCPD_DEFAULTS"; then
  echo "错误：未能从 $ODHCPD_DEFAULTS 中删除 dhcp.lan.ra_flags（managed-config/other-config）" >&2
  exit 1
fi

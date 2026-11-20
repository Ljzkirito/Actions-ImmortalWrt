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

# 默认包：用 odhcp6c + odhcpd-ipv6only 取代 ipv6helper
[ -f include/target.mk ] && \
  sed -i -E 's/^([[:space:]]*)ipv6helper(.*)$/\1odhcp6c odhcpd-ipv6only\2/' include/target.mk || \
  echo "警告：未能替换 include/target.mk 中的 ipv6helper，继续构建" >&2

# 关闭 LAN 的 DHCPv6（保持 RA 为 server，仅用 SLAAC）；ipv6helper 已不在
# 默认包中，60-ipv6-hybrid 不会再把它覆盖回 hybrid。删除 ra_flags 的
# managed-config/other-config 行（注意 odhcpd 未显式配置时仍默认带 O 标志）。
# odhcpd.defaults 首次启动时生成 /etc/config/dhcp
ODHCPD_DEFAULTS=package/network/services/odhcpd/files/odhcpd.defaults
sed -i -E 's|^(set dhcp\.lan\.dhcpv6=).*|\1disabled|' "$ODHCPD_DEFAULTS"
sed -i '/^add_list dhcp\.lan\.ra_flags=/d' "$ODHCPD_DEFAULTS"

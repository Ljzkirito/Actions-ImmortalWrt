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

echo "src-git helloworld https://github.com/fw876/helloworld.git;master" >> "feeds.conf.default"
echo "src-git customsd https://github.com/Ljzkirito/smartdns-openwrt.git;Release45-conf" >> "feeds.conf.default"

# Replace /lib/netifd/ppp-down
# https://github.com/hanwckf/immortalwrt-mt798x/issues/57
cat >> package/network/services/ppp/files/lib/netifd/ppp-down <<EOF
while true; do
  if ubus -S list "network.interface.wan_6"; then
    # ubus call network.interface.wan_6 down
    logger "waiting wan_6 down..."
    sleep 1
  else
    break
  fi
done
EOF
#按照mtk-sdk和最新openwrt主线的有线驱动，mt7981的ADMAv2存在不可修复的问题，immortalwrt-mt798x已参照上述源码将mt7981 ADMAv2回退至ADMAv1。
#当有线驱动使用ADMAv1时，每个PPE最多支持16384个Entry。每个NAT连接需要占用2个Entry（进站和出站方向）。
sed -i 's/nf_conntrack_max=65536/nf_conntrack_max=16384/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
sed -i 's/nf_conntrack_buckets=65536/nf_conntrack_buckets=16384/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 取消Dnsmasq缓存，由smartdns负责。不修改ttl
sed -i 's/cachesize\t8000/cachesize\t0/g' package/network/services/dnsmasq/files/dhcp.conf
sed -i 's/mini_ttl\t3600/mini_ttl\t0/g' package/network/services/dnsmasq/files/dhcp.conf

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

# Replace /lib/netifd/ppp-down
# https://github.com/hanwckf/immortalwrt-mt798x/issues/57
#cat >> package/network/services/ppp/files/lib/netifd/ppp-down <<EOF
#while true; do
#  if ubus -S list "network.interface.wan_6"; then
#    # ubus call network.interface.wan_6 down
#    logger "waiting wan_6 down..."
#    sleep 1
#  else
#    break
#  fi
#done
#EOF

# 取消Dnsmasq缓存，由smartdns负责。不修改ttl
#sed -i 's/cachesize\t8000/cachesize\t0/g' package/network/services/dnsmasq/files/dhcp.conf
#sed -i 's/mini_ttl\t3600/mini_ttl\t0/g' package/network/services/dnsmasq/files/dhcp.conf

# Remove 6in4
sed -i 's/ +6in4//g' package/emortal/ipv6-helper/Makefile
sed -i '/hotplug.d/d' package/emortal/ipv6-helper/Makefile
rm -fv package/emortal/ipv6-helper/files/60-6in4

cat >> package/mtk/drivers/mt_wifi/patches-7673/999-Increase-token-rx-cnt.patch <<EOF
--- a/mt_wifi/chips/mt7981.c
+++ b/mt_wifi/chips/mt7981.c
@@ -11711,7 +11711,7 @@
 	chip_cap->tkn_info.hw_tx_token_cnt = 8192;
 #ifdef MEMORY_SHRINK
 #ifdef MEMORY_SHRINK_AGGRESS
-	chip_cap->tkn_info.token_rx_cnt = 4592;
+	chip_cap->tkn_info.token_rx_cnt = 6144;
 #else
 	chip_cap->tkn_info.token_rx_cnt = 12288;
 #endif	/* MEMORY_SHRINK_AGGRESS */
EOF

# 进入仓库主分支后执行，直接应用Pull requests补丁
# fix issue 353 and use swconfig to get port flow
curl -sL https://github.com/hanwckf/immortalwrt-mt798x/pull/355.patch | git apply -
# Fix 802.11k RRM_PeerNeighborReqAction snprintf error
curl -sL https://github.com/hanwckf/immortalwrt-mt798x/pull/416.patch | git apply -
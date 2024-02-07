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

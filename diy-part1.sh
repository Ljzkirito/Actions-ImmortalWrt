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

# Rust-host test
git clone --depth=1 -b openwrt-23.05 https://github.com/immortalwrt/packages packages-temp
echo "download rust/host form immortalwrt/packages-openwrt-23.05"
cp -r packages-temp/lang/rust feeds/packages/lang
rm -rf packages-temp
ls -a
echo "Rust/host $(grep "PKG_VERSION" feeds/packages/lang/rust/Makefile)"

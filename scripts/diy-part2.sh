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
# Clone the custom repo into a dedicated folder under package/ (which the build
# scans recursively), then delete the same-named package folders installed
# from feeds so the local copy is the only one.
SMARTDNS_DIR=package/smartdns-openwrt
rm -rf "$SMARTDNS_DIR"
git clone --depth=1 -b PikuZheng https://github.com/Ljzkirito/smartdns-openwrt "$SMARTDNS_DIR"

for pkgdir in "$SMARTDNS_DIR"/*/; do
  [ -f "$pkgdir/Makefile" ] || continue
  pkgname=$(basename "$pkgdir")
  find feeds -type d -name "$pkgname" -prune \
    -exec sh -c '[ -f "$1/Makefile" ] && rm -rfv "$1"' _ {} \;
done

# Drop the symlinks that "feeds install -a" left pointing at the removed dirs.
find package/feeds -xtype l -delete 2>/dev/null || true

# Replace luci-theme-argon
rm -rfv feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon
git -C feeds/luci/themes/luci-theme-argon checkout 1991a8e29ef6a086fb566517675edc85b1be629a

#https://github.com/immortalwrt/packages/issues/1607
#Fix Rust compilation failure（21.02 no rust)
if [ -f feeds/packages/lang/rust/Makefile ]; then
  sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile
fi

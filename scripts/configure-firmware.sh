#!/bin/bash
#
# Configure firmware options for the Actions-MT7981 build.
#
# Called by .github/workflows/Build_mt7981.yml (step "Configure firmware options").
#
# Required environment:
#   CONFIG_FILE            build config path, relative to the Actions-MT7981 repo root
#   LAN_IP                 LAN IPv4 address in CIDR form (RFC 1918 private only,
#                          e.g. 192.168.6.1/24); the prefix sets the LAN netmask
#                          in package/base-files/files/bin/config_generate
#   MEMORY_SHRINK_AGGRESS  true/false
#   ZRAM_SWAP              true/false
#   IPTV_PACKAGES          true/false
#   MTKHQOS                true/false
#
# LAN_IP must be an RFC 1918 private address (10.0.0.0/8, 172.16.0.0/12 or
# 192.168.0.0/16) with a /N prefix; the netmask in config_generate is derived
# from that prefix (e.g. /24 -> 255.255.255.0). The prefix must be at least the
# block prefix (/8, /12 or /16) so that the subnet stays inside RFC 1918, and at
# most /30. The host bits must not be all 0 (network address) or all 1
# (broadcast address); use a usable host address inside the subnet.
#
# If LAN_IP is invalid (wrong format, not an RFC 1918 address, a bad prefix, or
# the network/broadcast address of its subnet), the script prints a warning and
# falls back to DEFAULT_LAN_IP (192.168.6.1/24) instead of failing the build.
#
# Run it from the Actions-MT7981 repo root (GitHub Actions does). The script
# changes into $GITHUB_WORKSPACE when set, otherwise it keeps the current
# directory; CONFIG_FILE and ImmortalWrt/ are resolved relative to it.

set -euo pipefail

# GitHub Actions always runs this step from the repository root with
# GITHUB_WORKSPACE set; the fallback keeps local runs working from the repo root.
cd "${GITHUB_WORKSPACE:-$(pwd)}"

[ -n "${CONFIG_FILE:-}" ] || { echo "错误：未设置 CONFIG_FILE" >&2; exit 1; }
[ -f "$CONFIG_FILE" ] || { echo "错误：找不到配置文件 $CONFIG_FILE" >&2; exit 1; }

# Remove stale entries for every option governed below, then append fresh ones
for cfg in \
  CONFIG_PACKAGE_kmod-tun \
  CONFIG_PACKAGE_kmod-warp \
  CONFIG_MTK_MEMORY_SHRINK_AGGRESS \
  CONFIG_PACKAGE_kmod-zram \
  CONFIG_PACKAGE_zram-swap \
  CONFIG_PACKAGE_luci-app-msd_lite \
  CONFIG_PACKAGE_luci-app-omcproxy \
  CONFIG_PACKAGE_mtkhqos_util \
  CONFIG_PACKAGE_luci-app-eqos-mtk; do
  sed -i "/$cfg/d" "$CONFIG_FILE"
done

# Make sure appends start on a new line even if the file has no trailing newline
if [ -n "$(tail -c 1 "$CONFIG_FILE")" ]; then
  echo >> "$CONFIG_FILE"
fi

# CONFIG_MTK_MEMORY_SHRINK_AGGRESS
if [ "${MEMORY_SHRINK_AGGRESS:-false}" = "true" ]; then
  echo "CONFIG_MTK_MEMORY_SHRINK_AGGRESS=y" >> "$CONFIG_FILE"
else
  echo "# CONFIG_MTK_MEMORY_SHRINK_AGGRESS is not set" >> "$CONFIG_FILE"
fi

# zram-swap (kmod-zram is pulled in automatically as its dependency)
if [ "${ZRAM_SWAP:-false}" = "true" ]; then
  echo "CONFIG_PACKAGE_zram-swap=y" >> "$CONFIG_FILE"
else
  echo "# CONFIG_PACKAGE_zram-swap is not set" >> "$CONFIG_FILE"
fi

# IPTV (luci-app-msd_lite + luci-app-omcproxy)
if [ "${IPTV_PACKAGES:-false}" = "true" ]; then
  echo "CONFIG_PACKAGE_luci-app-msd_lite=y" >> "$CONFIG_FILE"
  echo "CONFIG_PACKAGE_luci-app-omcproxy=y" >> "$CONFIG_FILE"
else
  echo "# CONFIG_PACKAGE_luci-app-msd_lite is not set" >> "$CONFIG_FILE"
  echo "# CONFIG_PACKAGE_luci-app-omcproxy is not set" >> "$CONFIG_FILE"
fi

# MTK HQoS (luci-app-eqos-mtk + mtkhqos_util)
if [ "${MTKHQOS:-false}" = "true" ]; then
  echo "CONFIG_PACKAGE_luci-app-eqos-mtk=y" >> "$CONFIG_FILE"
  echo "CONFIG_PACKAGE_mtkhqos_util=y" >> "$CONFIG_FILE"
else
  echo "# CONFIG_PACKAGE_luci-app-eqos-mtk is not set" >> "$CONFIG_FILE"
  echo "# CONFIG_PACKAGE_mtkhqos_util is not set" >> "$CONFIG_FILE"
fi

grep -n -E "CONFIG_(MTK_MEMORY_SHRINK_AGGRESS|PACKAGE_kmod-zram|PACKAGE_zram-swap|PACKAGE_luci-app-msd_lite|PACKAGE_luci-app-omcproxy|PACKAGE_luci-app-eqos-mtk|PACKAGE_mtkhqos_util)" "$CONFIG_FILE" || true

# LAN IP: CIDR notation (RFC 1918 private address + prefix), e.g. 192.168.6.1/24.
DEFAULT_LAN_IP="192.168.6.1/24"
LAN_CIDR_RE='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])/[0-9]{1,2}$'

# Parse "<private IPv4>/<prefix>" into LAN_ADDR, PREFIX and NETMASK.
# Prints a Chinese warning and returns 1 when the input is invalid.
lan_parse() {
  local input=$1 addr prefix ip1 ip2 ip3 ip4 min_prefix mask
  local ip_int host_bits host_mask host_part

  if ! printf '%s\n' "$input" | grep -Eq "$LAN_CIDR_RE"; then
    echo "警告：LanIP '$input' 格式不正确，应为 CIDR 形式（IPv4/前缀，例如 $DEFAULT_LAN_IP）" >&2
    return 1
  fi

  addr="${input%/*}"
  prefix="${input##*/}"

  IFS=. read -r ip1 ip2 ip3 ip4 <<< "$addr"
  case "$ip1.$ip2" in
    10.*)                            min_prefix=8 ;;
    172.1[6-9]|172.2[0-9]|172.3[01]) min_prefix=12 ;;
    192.168)                         min_prefix=16 ;;
    *)
      echo "警告：LanIP '$input' 中的地址 $addr 不是 RFC 1918 私有地址，仅支持 10.0.0.0/8、172.16.0.0/12、192.168.0.0/16" >&2
      return 1
      ;;
  esac

  prefix=$((10#$prefix))
  if [ "$prefix" -lt "$min_prefix" ] || [ "$prefix" -gt 30 ]; then
    echo "警告：LanIP '$input' 的前缀 /$prefix 无效，该网段允许 /$min_prefix 到 /30（前缀过小会超出 RFC 1918 网段，超过 /30 不可用）" >&2
    return 1
  fi

  # The host bits must not be all 0 (network address) or all 1 (broadcast address).
  host_bits=$((32 - prefix))
  host_mask=$(( (1 << host_bits) - 1 ))
  ip_int=$(( (ip1 << 24) | (ip2 << 16) | (ip3 << 8) | ip4 ))
  host_part=$(( ip_int & host_mask ))
  if [ "$host_part" -eq 0 ]; then
    echo "警告：LanIP '$input' 中的地址 $addr 是该子网的网络地址（主机位全 0），请改用子网内可分配的主机地址" >&2
    return 1
  fi
  if [ "$host_part" -eq "$host_mask" ]; then
    echo "警告：LanIP '$input' 中的地址 $addr 是该子网的广播地址（主机位全 1），请改用子网内可分配的主机地址" >&2
    return 1
  fi

  LAN_ADDR="$addr"
  PREFIX="$prefix"
  mask=$(( (0xFFFFFFFF << (32 - PREFIX)) & 0xFFFFFFFF ))
  NETMASK="$(( (mask >> 24) & 255 )).$(( (mask >> 16) & 255 )).$(( (mask >> 8) & 255 )).$(( mask & 255 ))"
  return 0
}

# Invalid input falls back to the default instead of failing the build.
LAN_INPUT="${LAN_IP:-$DEFAULT_LAN_IP}"
if ! lan_parse "$LAN_INPUT"; then
  echo "警告：LanIP 输入无效，已回退到默认值 $DEFAULT_LAN_IP" >&2
  LAN_INPUT="$DEFAULT_LAN_IP"
  lan_parse "$LAN_INPUT" || { echo "错误：默认值 $LAN_INPUT 无效" >&2; exit 1; }
fi

CONFIG_GENERATE="ImmortalWrt/package/base-files/files/bin/config_generate"
[ -f "$CONFIG_GENERATE" ] || { echo "错误：找不到 $CONFIG_GENERATE" >&2; exit 1; }
grep -qE '192\.168\.[0-9]{1,3}\.1' "$CONFIG_GENERATE" || {
  echo "错误：$CONFIG_GENERATE 中找不到可替换的 192.168.x.1 默认 LAN IP" >&2
  exit 1
}

# Replace the LAN IP defaults and the default static-interface netmask.
sed -i -E "s/192\.168\.[0-9]{1,3}\.1\b/$LAN_ADDR/g" "$CONFIG_GENERATE"
sed -i -E 's|netm=\$\{netmask:-"255\.255\.255\.0"\}|netm=${netmask:-"'"$NETMASK"'"}|' "$CONFIG_GENERATE"
grep -qF "netm=\${netmask:-\"$NETMASK\"}" "$CONFIG_GENERATE" || {
  echo "错误：未能把 $CONFIG_GENERATE 中的默认掩码改为 $NETMASK" >&2
  exit 1
}

echo "LAN IP 已设置为 $LAN_ADDR/$PREFIX（掩码 $NETMASK）："
grep -nF "$LAN_ADDR" "$CONFIG_GENERATE" || true
grep -nF "netm=\${netmask:-\"$NETMASK\"}" "$CONFIG_GENERATE" || true

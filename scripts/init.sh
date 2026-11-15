#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) ImmortalWrt.org
#
# Simplified for Ubuntu 24.04 (noble) GitHub Actions runners:
#   - only the noble apt sources / dependencies are kept
#   - Debian and other Ubuntu branches (bionic/focal/jammy/...) are removed
#   - the China-network (CHN_NET) checks and China mirrors are removed,
#     GitHub Actions runners are not in mainland China

echo "[INFO] Checking system info..."

VERSION_CODENAME="$(source /etc/os-release; echo "$VERSION_CODENAME")"

[ "$VERSION_CODENAME" == "noble" ] || {
	echo "[ERROR] This script only supports Ubuntu 24.04 (noble), got $VERSION_CODENAME."
	exit 1
}

[ "$(uname -m)" == "x86_64" ] || { echo "[ERROR] Unsupported architecture, use AMD64 instead."; exit 1; }
[ "$(whoami)" == "root" ] || { echo "[ERROR] You must run this script as root."; exit 1; }

GCC_VERSION="13"
LLVM_VERSION="23"
NODE_DISTRO="nodistro"
NODE_KEY="nodesource-repo.gpg.key"
NODE_VERSION="24"
UBUNTU_CODENAME="$VERSION_CODENAME"

echo "[INFO] Updating apt source lists..."

apt update -y
apt install -y apt-transport-https gnupg2

mkdir -p "/etc/apt/keyrings" "/etc/apt/sources.list.d" "/etc/apt/trusted.gpg.d"

cat <<EOF >"/etc/apt/sources.list.d/nodesource.list"
deb https://deb.nodesource.com/node_${NODE_VERSION}.x $NODE_DISTRO main
EOF
curl -fsL "https://deb.nodesource.com/gpgkey/$NODE_KEY" -o "/etc/apt/trusted.gpg.d/nodesource.asc"

cat <<EOF >"/etc/apt/sources.list.d/yarn.list"
deb https://dl.yarnpkg.com/debian/ stable main
EOF
curl -fsL "https://dl.yarnpkg.com/debian/pubkey.gpg" -o "/etc/apt/trusted.gpg.d/yarn.asc"

cat <<EOF >"/etc/apt/sources.list.d/git-core-ubuntu-ppa.list"
deb https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
deb-src https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
EOF
curl -fsL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf911ab184317630c59970973e363c90f8f1b6217" -o "/etc/apt/trusted.gpg.d/git-core-ubuntu-ppa.asc"

cat <<EOF >"/etc/apt/sources.list.d/llvm-toolchain.list"
deb https://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-$LLVM_VERSION main
deb-src https://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-$LLVM_VERSION main
EOF
curl -fsL "https://apt.llvm.org/llvm-snapshot.gpg.key" -o "/etc/apt/trusted.gpg.d/llvm-toolchain.asc"

cat <<EOF >"/etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.list"
deb https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
deb-src https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
EOF
curl -fsL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x876b22ba887ca91614b5323fc631127f87fa12d1" -o "/etc/apt/trusted.gpg.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.asc"

cat <<EOF >"/etc/apt/sources.list.d/github-cli.list"
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main
EOF
curl -fsL "https://cli.github.com/packages/githubcli-archive-keyring.gpg" -o "/etc/apt/keyrings/githubcli-archive-keyring.gpg"

apt update -y

echo "[INFO] Installing dependencies..."

apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison \
	build-essential bzip2 ccache cmake cpio curl device-tree-compiler ecj fakeroot \
	fastjar flex gawk gettext genisoimage gnutls-dev gperf haveged help2man intltool \
	irqbalance jq lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev \
	libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libreadline-dev libssl-dev \
	libtool libyaml-dev libz-dev lrzsz msmtp nano ninja-build p7zip p7zip-full patch \
	pkgconf libpython3-dev python3 python3-pip python3-cryptography python3-docutils \
	python3-ply python3-pyelftools python3-requests qemu-utils quilt re2c rsync scons \
	sharutils squashfs-tools subversion swig texinfo uglifyjs unzip vim wget xmlto \
	zlib1g-dev zstd xxd

apt install -y git

apt install -y "gcc-$GCC_VERSION" "g++-$GCC_VERSION" "gcc-$GCC_VERSION-multilib" "g++-$GCC_VERSION-multilib"
for i in "gcc-$GCC_VERSION" "g++-$GCC_VERSION" "gcc-ar-$GCC_VERSION" "gcc-nm-$GCC_VERSION" "gcc-ranlib-$GCC_VERSION"; do
	ln -svf "$i" "/usr/bin/${i%-$GCC_VERSION}"
done
ln -svf "/usr/bin/g++" "/usr/bin/c++"
[ -e "/usr/include/asm" ] || ln -svf "/usr/include/$(gcc -dumpmachine)/asm" "/usr/include/asm"

apt install -y "clang-$LLVM_VERSION" "libclang-$LLVM_VERSION-dev" "lld-$LLVM_VERSION" "liblld-$LLVM_VERSION-dev" "llvm-$LLVM_VERSION"
for i in "/usr/lib/llvm-$LLVM_VERSION/bin"/*; do
	ln -svf "$i" "/usr/bin/${i##*/}"
done
ln -svf "/usr/lib/llvm-$LLVM_VERSION" "/usr/lib/llvm"

apt install -y nodejs yarn

apt install -y golang-1.27-go
rm -rf "/usr/bin/go" "/usr/bin/gofmt"
ln -svf "/usr/lib/go-1.27/bin/go" "/usr/bin/go"
ln -svf "/usr/lib/go-1.27/bin/gofmt" "/usr/bin/gofmt"

apt install gh -y

apt clean -y

if TMP_DIR="$(mktemp -d)"; then
	pushd "$TMP_DIR"
else
	echo "[ERROR] Failed to create a tmp directory."
	exit 1
fi

UPX_REV="5.3.0"
curl -fLO "https://github.com/upx/upx/releases/download/v${UPX_REV}/upx-$UPX_REV-amd64_linux.tar.xz"
tar -Jxf "upx-$UPX_REV-amd64_linux.tar.xz"
rm -rf "/usr/bin/upx" "/usr/bin/upx-ucl"
cp -fp "upx-$UPX_REV-amd64_linux/upx" "/usr/bin/upx-ucl"
chmod 0755 "/usr/bin/upx-ucl"
ln -svf "/usr/bin/upx-ucl" "/usr/bin/upx"

curl -fLO "https://raw.githubusercontent.com/openwrt/openwrt/main/tools/padjffs2/src/padjffs2.c"
gcc -Wall -Werror -o "padjffs2" "padjffs2.c"
strip "padjffs2"
rm -rf "padjffs2.c" "/usr/bin/padjffs2"
cp -fp "padjffs2" "/usr/bin/padjffs2"

git clone --filter=blob:none --no-checkout "https://github.com/openwrt/luci.git" "po2lmo"
pushd "po2lmo"
git config core.sparseCheckout true
echo "modules/luci-base/src" >> ".git/info/sparse-checkout"
git checkout
cd "modules/luci-base/src"
make po2lmo
strip "po2lmo"
rm -rf "/usr/bin/po2lmo"
cp -fp "po2lmo" "/usr/bin/po2lmo"
popd

popd
rm -rf "$TMP_DIR"

echo "[SUCCESS] All dependencies have been installed."

#!/bin/bash
uname_m="aarch64"
uname_r="6.1.31-v8.1.el9.altarch"
zfs_r="2.1.14"
sudo dnf update -y
mkdir -p "$HOME"/prj_github/zfs_build_dkms_hints-downstream/zfs-k"$uname_r"
cd "$HOME"/prj_github/zfs_build_dkms_hints-downstream/zfs-k"$uname_r"
sudo dnf install -y yum-utils
sudo yumdownloader --source libtirpc
sudo dnf install -y krb5-devel
sudo dnf install -y rpm-build autoconf automake libtool
rpmbuild -ra libtirpc-1.3.3-8.el9_4.src.rpm
sudo dnf install -y "$HOME"/rpmbuild/RPMS/"$uname_m"/libtirpc-debugsource-1.3.3-8.el9."$uname_m".rpm
sudo dnf install -y "$HOME"/rpmbuild/RPMS/"$uname_m"/libtirpc-devel-1.3.3-8.el9."$uname_m".rpm
wget https://github.com/openzfs/zfs/releases/download/zfs-"$zfs_r"/zfs-"$zfs_r".tar.gz -O zfs-"$zfs_r".tar.gz
tar -xzf zfs-"$zfs_r".tar.gz
cd zfs-"$zfs_r"
sudo dnf install -y rpm-build
sudo dnf install -y raspberrypi2-kernel4-devel
sudo dnf install -y -y epel-release
sudo dnf install -y gcc make autoconf automake libtool dkms python3 python3-cffi python3-packaging python3-setuptools python3-devel openssl-devel elfutils-libelf-devel zlib-devel libaio-devel libattr-devel libblkid-devel libcurl-devel libffi-devel libudev-devel libuuid-devel
sh autogen.sh
./configure
make -s -j4 rpm
sudo dnf install -y ./libnvpair3-"$zfs_r"-1.el9."$uname_m".rpm ./libuutil3-"$zfs_r"-1.el9."$uname_m".rpm ./libzfs5-"$zfs_r"-1.el9."$uname_m".rpm ./libzpool5-"$zfs_r"-1.el9."$uname_m".rpm ./zfs-"$zfs_r"-1.el9."$uname_m".rpm ./zfs-dkms-"$zfs_r"-1.el9.noarch.rpm

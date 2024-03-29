#!/bin/bash
uname_m="aarch64"
uname_r="6.1.21-v8+"
zfs_r="2.1.14"
sudo apt update -y
sudo apt upgrade -y
mkdir -p "$HOME"/prj_github/zfs_build_dkms_hints/zfs-k"$uname_r"
cd "$HOME"/prj_github/zfs_build_dkms_hints/zfs-k"$uname_r"
wget https://github.com/openzfs/zfs/releases/download/zfs-"$zfs_r"/zfs-"$zfs_r".tar.gz -O zfs-"$zfs_r".tar.gz
tar -xzf zfs-"$zfs_r".tar.gz
cd zfs-"$zfs_r"
sudo apt install -y alien build-essential fakeroot gawk
sudo apt install -y raspberrypi-kernel-headers
sudo apt install -y gcc make autoconf automake libtool dkms python3 python3-cffi python3-packaging python3-setuptools python3-dev uuid-dev zlib1g-dev libaio-dev libattr1-dev libblkid-dev libcurl4-openssl-dev libelf-dev libffi-dev libssl-dev libudev-dev
sh autogen.sh
./configure
make -s -j4 deb
sudo apt install -y ./zfs-dkms_"$zfs_r"-1_arm64.deb

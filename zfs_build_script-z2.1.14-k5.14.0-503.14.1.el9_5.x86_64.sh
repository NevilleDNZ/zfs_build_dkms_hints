#!/bin/bash
uname_m="x86_64"
uname_r="5.14.0-503.14.1.el9_5.x86_64"
zfs_r="2.1.14"
sudo dnf update -y
mkdir -p "$HOME"/zfs_build_dkms_hints-downstream/zfs-k"$uname_r"
cd "$HOME"/zfs_build_dkms_hints-downstream/zfs-k"$uname_r"
sudo dnf install -y yum-utils
sudo yumdownloader --source libtirpc
sudo dnf install -y krb5-devel
sudo dnf install -y rpm-build autoconf automake libtool
rpmbuild -ra libtirpc-1.3.3-9.el9.src.rpm
sudo dnf install -y "$HOME"/rpmbuild/RPMS/"$uname_m"/libtirpc-debugsource-1.3.3-9.el9."$uname_m".rpm

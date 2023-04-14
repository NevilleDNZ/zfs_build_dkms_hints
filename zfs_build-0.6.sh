#!/usr/bin/bash
#et -x
if [ "/$1/" == "/--dkms/" ]; then
cat << end_cat
NAME
    zfs_build-0.6.sh

SYNOPSIS
    zfs_build-0.6.sh # options set internally with OPT_ env variables

DESCRIPTION
    A simple "hack" to TRY and build zfs across a range of platforms.
    Includes a crude Step/Skip/Continue shell-script line debugger.

    Basically, set:
      * Mode=Step # prompt before each command
      * Then (initially) manually "[1]Step" through each build command 
        - check for error tickled by your OSes quirks...
      * Note: A copy of each command is logged into a zfs_build_script*.sh for manual review
        - prj_ng/zfs_build/zfs_build_script_5.14.0-162.23.1.el9_1.x86_64.sh
      * Then (finally) manually "[1]Step" through each build command 
         - Mode=Continue # to runn
Initially tested on:
  * RHEL9.1 - 5.14.0-162.23.1.el9_1.x86_64
  * RaspberrryPi/Debian 6.1.21-v8+
  * rocky9-1-aarch64 6.1.8-v8.1.el9.altarch.1

end_cat
fi

zfs_r=2.1.9 # stable?

# if false; for 2.1.99
if true; then
    OPT_GET="wget"
else # warning, this 2.1.99 is under constant enhancement/review
    zfs_r=2.1.99 # beta
    OPT_GET="git clone"
    OPT_GET="git pull"
fi

OPT_MOD=kmod
OPT_MOD=dkms

ZFS_TAR=https://github.com/openzfs/zfs/releases/download/zfs-$zfs_r/zfs-$zfs_r.tar.gz
ZFS_GIT=https://github.com/openzfs/zfs

Mode=Step # prompt before each command
Mode=Skip
Mode=Continue
Mode_l="Step Skip Continue Shell Exit"

#Mode=Step # QQQ move this line to the beginning or end to enable/disable line debugging!! :-) #

bold=`tput bold`
rev=`tput rev`
sgr0=`tput sgr0`

PKG_MGR=dnf
for mgr in dnf apt yum; do
    if [ -f "/usr/bin/$mgr" ]; then
        PKG_MGR=$mgr
	break
    fi
done

#echo snrvmpio | sed 's/./echo "&=$(uname -&);"; /g' | sh
#s=Linux;
#n=dell-xps-14z-rhel9-1-x86-64-8g;
#r=5.14.0-162.22.2.el9_1.x86_64;
#v=#1 SMP PREEMPT_DYNAMIC Wed Mar 15 14:44:24 EDT 2023;
#m=x86_64;
#p=x86_64;
#i=x86_64;
#o=GNU/Linux;

uname_m="`uname -m`"
uname_r="`uname -r`"

uname_M=$uname_m
if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
    true
else
    [ "$uname_M" == "aarch64" ] && uname_M=arm64
fi

PKG_UPDATE="sudo $PKG_MGR update -y"
PKG_UPGRADE="sudo $PKG_MGR upgrade -y" # apt only
PKG_INSTALL="sudo $PKG_MGR install -y"
if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
    PKG_LIST_INSTALLED="rpm -qa"
else
    PKG_LIST_INSTALLED="$PKG_MGR list --installed"
fi

if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
    _DEVEL=-devel
    PKG=rpm
    VERSEP=- # -2.1.9 in libzfs5-2.1.9-1.el9.x86_64.rpm
else
    _DEVEL=-dev
    PKG=deb
    VERSEP=_ # eg: _2.1.9 in libzfs5_2.1.9-1_arm64.deb
fi
_PKG=.$PKG

qq='"'

TRACE0(){
    cmd="$*"
    echo $PWD: Running: "$rev$@$sgr0";
    if [ "$Script" != "" ]; then
        echo Script:+= "$rev$@$sgr0"
        echo "$@" | sed "s/$re_uname_r/$qq\$uname_r$qq/g; s/$re_uname_m/$qq\$uname_m$qq/g; s/$re_zfs_r/$qq\$zfs_r$qq/g" >> $Script
    fi
    "$@";
}

EXCEPTION(){
    echo Exception: "$cmd" 
    sleep 6
    exit
}

TRACE(){
    cmd="$*"
    case "$Mode" in
        (Skip) echo Skip: "$rev$@$sgr0";;
        (Continue) TRACE0 "$@";;
	(*)
	    # echo "$@"
	    PS3="Next [$bold$*$sgr0]? Enter option nr.: "
	    select opt_Mode in $Mode_l; do
		case "$opt_Mode" in 
		    (Skip) echo Skip; break;;
		    (Continue)
			Mode=Continue
			break;;
		    (Shell) $SHELL;;
		    (Exit) exit; break;;
		    (Step) TRACE0 "$@"; break;;
		    (*) echo "Select [$Mode_l]: $opt_Mode number?";;
		esac
	    done
	;;
    esac
}

NEWEST(){
    ls -dt "$*" | head -1
}

eval `cat /etc/os-release`

cat << end_rhel91 > /dev/null
NAME="Red Hat Enterprise Linux"
VERSION="9.1 (Plow)"
ID="rhel"
ID_LIKE="fedora"
VERSION_ID="9.1"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Red Hat Enterprise Linux 9.1 (Plow)"
ANSI_COLOR="0;31"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:redhat:enterprise_linux:9::baseos"
HOME_URL="https://www.redhat.com/"
DOCUMENTATION_URL="https://access.redhat.com/documentation/red_hat_enterprise_linux/9/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"

REDHAT_BUGZILLA_PRODUCT="Red Hat Enterprise Linux 9"
REDHAT_BUGZILLA_PRODUCT_VERSION=9.1
REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.1"
end_rhel91

#platform="$ID$VERSION_ID"
zfs_uname_r="zfs-k$uname_r"

zfs_build_dir="$HOME/prj_ng/zfs_build"

re_esc(){
    sed "s/[.*+]/[&]/g"
}

if true; then
# FORCE zfs_build.sh to create a targeted zfs_build_script_$uname_r.sh scipt instead
   Script=$zfs_build_dir/zfs_build_script_$uname_r.sh
   echo "#!/bin/bash" > $Script
   echo uname_m='"'"$(uname -m)"'"' >> $Script
   re_uname_m="$(echo $uname_m | re_esc )"
   echo uname_r='"'"$(uname -r)"'"' >> $Script
   re_uname_r="$(echo $uname_r | re_esc )"
   echo zfs_r='"'"$zfs_r"'"' >> $Script
   re_zfs_r="$(echo $zfs_r | re_esc )"
fi

report_build_env(){
   echo PKG_MGR: $PKG_MGR
   echo zfs_build_dir: $zfs_build_dir
   echo Script: $Script
}
report_build_env

##install libtirpc-devel
TRACE $PKG_UPDATE
[ "$PKG_MGR" == "apt" ] && TRACE $PKG_UPGRADE

echo NOTE: if a fresh kernel was just installed you MAY need to manually:
echo "1. remove previous kernel headers/$_DEVEL $_PKG"
echo "2. remove previous zfs $_PKG"s
echo "3. sudo init 6"

TRACE0 mkdir -p $zfs_build_dir/$zfs_uname_r || EXCEPTION
TRACE0 cd $zfs_build_dir/$zfs_uname_r || EXCEPTION


# libtirpc-devel is missing from RHEL...
if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
    
    TRACE $PKG_INSTALL yum-utils
    TRACE sudo yumdownloader --source libtirpc

    TRACE $PKG_INSTALL krb5$_DEVEL
    TRACE $PKG_INSTALL rpm-build autoconf automake libtool
    #TRACE rpmbuild -ra libtirpc-1.3.3-0.el9.src.rpm
    TRACE rpmbuild -ra `NEWEST libtirpc-*.src.rpm`
    #TRACE $PKG_INSTALL `NEWEST ~/rpmbuild/RPMS/x86_64/libtirpc-devel-1.3.3-0.el9.x86_64.rpm`
    TRACE $PKG_INSTALL `NEWEST ~/rpmbuild/RPMS/$uname_m/libtirpc$_DEVEL-*.$uname_m.rpm`
fi

## install zfs
## ignore - dkms - not avail in RHEL9
##      install dkms
# TRACE $PKG_INSTALL libtirpc-devel
case "$OPT_GET" in
    (git*)
        TRACE $PKG_INSTALL git
        #TRACE git pull https://github.com/openzfs/zfs
        #TRACE git clone https://github.com/openzfs/zfs
        TRACE $OPT_GET $ZFS_GIT
        TRACE0 cd zfs || EXCEPTION
        TRACE git checkout master
    ;;
    (wget*|*)
	
	tarball=`basename $ZFS_TAR`
        TRACE $OPT_GET $ZFS_TAR -O $tarball
        TRACE tar -xzf $tarball
	pwd; ls -l
        TRACE0 cd zfs-$zfs_r || EXCEPTION
    ;;
esac

re_uname_r="$(uname -r | re_esc )"
re_uname_m="$(uname -m | re_esc )"

# figure out which kernel based on `uname -r`
#kernel_devel="$($PKG_LIST_INSTALLED | sed "/$re_uname_r/"'!d;'"s/[-_]$re_uname_r.*//;"'/kernel[^-]*'$_DEVEL'$/!d')" # assumed -dev installed
kernel_devel="$($PKG_LIST_INSTALLED | sed "/$re_uname_r/"'!d;'"s/[-_]$re_uname_r.*//;"'/kernel[0-9]*$/!d; s/$/'$_DEVEL/g)"
# returns: raspberrypi2-kernel4-devel or kernel-devel or empty

if [ "$kernel_devel" == "" ]; then # rpi doesnt include release numbering
    kernel_devel=raspberrypi-kernel-headers
#else
# RHEL dkms: "kernel-devel-matched" x86_64 5.14.0-162.23.1.el9_1 rhel-9-for-x86_64-appstream-rpms
fi

if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
    TRACE $PKG_INSTALL rpm-build
else
    TRACE $PKG_INSTALL alien build-essential fakeroot gawk
fi

if [ "$PKG_MGR" == "yum" -o "$PKG_MGR" == "dnf" ]; then
# TRACE $PKG_INSTALL gcc make autoconf automake libtool rpm-build libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$uname_r python3 python3-devel python3-setuptools python3-cffi libffi-devel libcurl-devel python3-packaging

    TRACE $PKG_INSTALL $kernel_devel
    TRACE $PKG_INSTALL gcc make autoconf automake libtool dkms \
        python3{,-cffi,-packaging,-setuptools} \
        {python3,openssl,elfutils-libelf,zlib}$_DEVEL \
        lib{aio,attr,blkid,curl,ffi,udev,uuid}$_DEVEL
else
# deb: $ sudo apt install -y build-essential autoconf automake libtool gawk alien fakeroot dkms libblkid-dev uuid-dev libudev-dev libssl-dev zlib1g-dev libaio-dev libattr1-dev libelf-dev python3 python3-dev python3-setuptools python3-cffi libffi-dev python3-packaging git libcurl4-openssl-dev
    TRACE $PKG_INSTALL $kernel_devel
    TRACE $PKG_INSTALL gcc make autoconf automake libtool dkms \
        python3{,-cffi,-packaging,-setuptools} \
	{python3,uuid,zlib1g}$_DEVEL \
        lib{aio,attr1,blkid,curl4-openssl,elf,ffi,ssl,udev}$_DEVEL
fi

TRACE sh autogen.sh
TRACE ./configure

#TRACE make -s -j$(nproc)
TRACE make -s -j$(nproc) $PKG

#Mode=Step # QQQ move this line to the beginning or end to enable/disable line debugging!! :-) #

# rocky9.1 FAILED: TRACE $PKG_INSTALL $(ls kmod-zfs-$uname_r*$uname_m.rpm {libnvpair3,libuutil3,libzfs5,libzpool5,zfs,zfs-test}-$zfs_r-*$uname_m.rpm | egrep -v "[-]debug|[-]devel" )
# FAILED ....Run [sudo dnf install -y libnvpair3-2.1.9-1.el9.aarch64.rpm libuutil3-2.1.9-1.el9.aarch64.rpm libzfs5-2.1.9-1.el9.aarch64.rpm libzpool5-2.1.9-1.el9.aarch64.rpm zfs-2.1.9-1.el9.aarch64.rpm zfs-test-2.1.9-1.el9.aarch64.rpm]? Enter No.:1
# rocky9.1 WORKED ... sudo dnf install `ls zfs-kmod-*.rpm {libnvpair3,libuutil3,libzfs5,libzpool5,zfs,zfs-test}-*.rpm | egrep -v "[-]debug|[-]devel|[.]src"`

# exclude zfs-test
case "$OPT_MOD" in
    (dkms) # Note: RPM suffix is .noarch.rpm, DEB suffix is .1_arm64.deb ??
	    EXCLUDE="dracut|kmod"; MOD="./zfs-dkms$VERSEP$zfs_r*$_PKG";;
    (kmod) EXCLUDE="dracut|dkms"; MOD="./kmod-zfs$VERSEP$uname_r*$uname_M$_PKG";;
esac

# ignore non-essential
install="$(ls $MOD ./{libnvpair3,libuutil3,libzfs5,libzpool5,zfs}$VERSEP$zfs_r-*$uname_M$_PKG | egrep -v "[-]debug|[-]devel|[.]src|$EXCLUDE" )"
TRACE $PKG_INSTALL $install

report_build_env

if [ "/$1/" == "/--dkms/" ]; then
cat << end_cat
==NOTES As of: Thu Apr 13 04pm AEST 2023==
https://openzfs.github.io/openzfs-docs/Getting%20Started/index.html

=== Raspberry Pi OS for arm64 ===
Seems to work with DKMS:
    cd ~/prj_ng/zfs_build/zfs-6.1.21-v8+/zfs-2.1.9 &&
    sudo apt install ./{zfs,zfs-dkms,libnvpair3,libuutil3,libzfs5,libzpool5}_2.1.9-1_arm64.deb &&
    exec init 6 # test: df -PhT
    
=== RockLinux 9.1 for aarch64 ===
    sudo dnf install dkms

=== RHEL 9.1 for aarch64 - needs dkms from epel ===
https://www.tecmint.com/install-epel-repo-rhel-9/
    sudo subscription-manager repos --enable codeready-builder-for-rhel-9-\$(arch)-rpms
    sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
    sudo dnf install dkms
# https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html
dnf install https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm

end_cat
   exit 1
fi

# sed -i.raw "s/$uname_r/"\$uname_r"/g" $SCRIPT

#TRACE exec sudo init 6 # to test new module

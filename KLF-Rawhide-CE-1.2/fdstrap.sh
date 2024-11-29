#!/bin/bash
# wiak minor mod to chroot dnf
set -e
rootfs=$(realpath "$1")
version="rawhide"
shift
while getopts -- ':v:' OPTION; do
    case $OPTION in
    v)
      version="${OPTARG[@]}"
      ;;
    *)
      echo "usage: fdstarp (rootfs) [options]"
      echo "    -v : use custom version (default: rawhide)"
      exit 1
    esac
done
[[ "$rootfs" == "" ]] && echo "Rootfs directory is invalid" && exit 1
tmp=$(mktemp -d)
mkdir -p "$rootfs" "$tmp/rootfs"
cd "$tmp"
link="https://kojipkgs.fedoraproject.org/packages/Fedora-Container-Base/Rawhide"
cver=$(wget -O - "$link" | sed "s/.*href=\"//g;s/\".*//g;s/\/$//g" | grep "^[0-9].*" | sort -V | tail -n 1)
wget -c -O fedora.tar.xz $link/$cver/images/Fedora-Container-Base-Rawhide-$cver.$(uname -m).tar.xz
tar -xf fedora.tar.xz
mv ./*/layer.tar ./rootfs
cd ./rootfs
tar -xf layer.tar
cat /etc/resolv.conf > ./etc/resolv.conf
mkdir -p ./etc/dnf && echo timeout=120 >> ./etc/dnf/dnf.conf  #wiak added 11Aug2023
#wiak removed  --use-host-config from below cos was preventing it working
chroot . dnf --nogpgcheck --releasever $version --installroot /fedora/ install dnf glibc-langpack-en \
    passwd rtkit audit util-linux rootfiles less sqlite lz4 ncurses which fedora-release -y
echo timeout=120 >> "$tmp"/rootfs/fedora/etc/dnf/dnf.conf  #wiak added 11Aug2023
mkdir -p "$rootfs"
mv "$tmp"/rootfs/fedora/* "$rootfs"
rm -rf "$tmp"


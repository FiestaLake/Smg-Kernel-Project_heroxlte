#!/sbin/sh
#
# Thanks to dwander for original script
# 

variant=$1

cd /tmp/script

tar -Jxf kernel.tar.xz $variant-boot.img

dd of=/dev/block/platform/155a0000.ufs/by-name/BOOT if=/tmp/script/$variant-boot.img



#!/bin/bash
#
# Thanks to morogoku, Arianoxx, pascua28, Tkkg1994 and djb77 for the script
#
# Fuesial-Kernel Clean Script
#

# Clean Build Data
make clean
make ARCH=arm64 distclean

rm -f ./hero2lte_build.log
rm -f ./herolte_build.log

# Remove Release files
rm -f $PWD/build/*.zip
rm -rf $PWD/build/temp
rm -rf $PWD/build/temp2
rm -f $PWD/arch/arm64/configs/tmp_defconfig

# Remove Created dtb
rm -f $RDIR/arch/$ARCH/boot/dts/*.dtb
rm -f $RDIR/arch/$ARCH/boot/dtb/*.dtb
rm -f $RDIR/arch/$ARCH/boot/boot.img-dtb
rm -f $RDIR/arch/$ARCH/boot/boot.img-zImage

# Recreate Ramdisk Placeholders
touch build/Q/ramdisk/apex/.PLACEHOLDER
touch build/Q/ramdisk/debug_ramdisk/.PLACEHOLDER
touch build/Q/ramdisk/dev/.PLACEHOLDER
touch build/Q/ramdisk/mnt/.PLACEHOLDER
touch build/Q/ramdisk/proc/.PLACEHOLDER
touch build/Q/ramdisk/sys/.PLACEHOLDER

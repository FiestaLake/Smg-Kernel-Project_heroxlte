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

# Removed Created dtb Folder
rm -rf $PWD/arch/arm64/boot/dtb

# Recreate Ramdisk Placeholders
echo "" > build/Q/ramdisk/apex/.placeholder
echo "" > build/Q/ramdisk/debug_ramdisk/.placeholder
echo "" > build/Q/ramdisk/dev/.placeholder
echo "" > build/Q/ramdisk/mnt/.placeholder
echo "" > build/Q/ramdisk/proc/.placeholder
echo "" > build/Q/ramdisk/sys/.placeholder

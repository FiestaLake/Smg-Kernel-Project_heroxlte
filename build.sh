#!/bin/bash
#
# Thanks to morogoku, Arianoxx, pascua28,
# ananjaser1211, Tkkg1994 and djb77 for the script
#
# Fuesial-Kernel Build Script developed by @FiestaLake
#

# SETUP
# -----
export K_NAME="Fuesial-Kernel"
export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=p
export PLATFORM_VERSION=9.0.0

DEFCONFIG=exynos8890_defconfig
HEROLTE_LOG=herolte.log
HERO2LTE_LOG=hero2lte.log
ZIP_NAME=$K_NAME-$MODEL.zip
#GCC_DIR=~/toolchain/gcc-10/bin/aarch64-none-linux-gnu-
GCC_DIR=~/toolchain/gcc-4/bin/aarch64-linux-android-
CLANG_DIR=~/toolchain/proton-clang/bin/clang

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
PORT=0


# FUNCTIONS
# ---------
FUNC_DELETE_PLACEHOLDERS()
{
	find . -name \.placeholder -type f -delete
        echo "Placeholders are deleted from ramdisk."
}

FUNC_CLEAN_DTB()
{
	if ! [ -d $RDIR/arch/$ARCH/boot/dts ] ; then
		echo "Non-existing directory : "$RDIR/arch/$ARCH/boot/dts"!"
	else
		echo "Removing files in : "$RDIR/arch/$ARCH/boot/dts/*.dtb"..."
		rm $RDIR/arch/$ARCH/boot/dts/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb/*.dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-zImage
	fi
}

FUNC_BUILD_KERNEL()
{
	cp -f $RDIR/arch/$ARCH/configs/$DEFCONFIG .config

        if [ $DEFCONFIG_SPLIT = NULL ]; then
                echo "No split config available!"
        else
                echo "Copying "$DEFCONFIG_SPLIT"..."
                cat $RDIR/arch/$ARCH/configs/$DEFCONFIG_SPLIT >> .config
        fi

	mv .config $RDIR/arch/$ARCH/configs/tmp_defconfig

	#FUNC_CLEAN_DTB
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			tmp_defconfig || exit -1

	if [ $CC_NAME == "clang" ]; then
                export KBUILD_COMPILER_STRING=$($CLANG_DIR --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CC=$CLANG_DIR \
			CLANG_TRIPLE=aarch64-linux-gnu- \
			CROSS_COMPILE=$GCC_DIR || exit -1
	elif [ $CC_NAME == "gcc" ]; then
		make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$GCC_DIR || exit -1
	fi

	rm -f $RDIR/arch/$ARCH/configs/tmp_defconfig
}

FUNC_BUILD_DTB()
{
	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}
	case $MODEL in
	herolte)
		DTSFILES="exynos8890-herolte_eur_open_04 exynos8890-herolte_eur_open_08
				exynos8890-herolte_eur_open_09 exynos8890-herolte_eur_open_10"
		;;
	hero2lte)
		DTSFILES="exynos8890-hero2lte_eur_open_04 exynos8890-hero2lte_eur_open_08"
		;;
	*)
		echo "Unknown device: "$MODEL"!"
		exit 1
		;;
	esac
	mkdir -p $OUTDIR $DTBDIR
	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}
	rm -f ./*
	echo "Processing dts files..."
	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done
	echo "Generating dtb.img..."
	$RDIR/scripts/dtbtool_exynos/dtbtool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
	echo "Done."
}

FUNC_BUILD_RAMDISK()
{
	echo ""
	echo "Building Ramdisk..."
	mv $RDIR/arch/$ARCH/boot/Image $RDIR/arch/$ARCH/boot/boot.img-zImage
	mv $RDIR/arch/$ARCH/boot/dtb.img $RDIR/arch/$ARCH/boot/boot.img-dtb

	cd $RDIR/build
	mkdir temp
	cp -rf aik/. temp
	cp -rf Q/. temp

	rm -f temp/split_img/boot.img-zImage
	rm -f temp/split_img/boot.img-dtb
	mv $RDIR/arch/$ARCH/boot/boot.img-zImage temp/split_img/boot.img-zImage
	mv $RDIR/arch/$ARCH/boot/boot.img-dtb temp/split_img/boot.img-dtb
	cd temp

	./repackimg.sh

	cp -f image-new.img $RDIR/build
	cd ..
	rm -rf temp
	echo SEANDROIDENFORCE >> image-new.img
	mv image-new.img $MODEL-boot.img
}

FUNC_BUILD_FLASHABLES()
{
	cd $RDIR/build
	mkdir temp2
	cp -rf zip/common/. temp2
    	mv *.img temp2/
	cd temp2
	echo ""
	echo "Compressing kernels..."
	tar cv *.img | xz -9 > kernel.tar.xz
	mv kernel.tar.xz script/
	rm -f *.img

	zip -9 -r ../$ZIP_NAME *

	cd ..
    	rm -rf temp2

}



# MAIN PROGRAM
# ------------

MAIN()
{
(
        echo "Building "$MODEL"..."
        if [ $START_TIME == NULL ]; then
	        START_TIME=`date +%s`
        fi
	FUNC_DELETE_PLACEHOLDERS
	FUNC_BUILD_KERNEL
	FUNC_BUILD_DTB
	FUNC_BUILD_RAMDISK
        FUNC_BUILD_FLASHABLES
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds."
) 2>&1 | tee -a ./$LOG
	echo "Your flashable file can be found in the build folder!"
}

MAIN2()
{
(
        echo "Building "$MODEL"..."
	START_TIME=`date +%s`
	FUNC_DELETE_PLACEHOLDERS
	FUNC_BUILD_KERNEL
	FUNC_BUILD_DTB
	FUNC_BUILD_RAMDISK
) 2>&1 | tee -a ./$LOG
}


# PROGRAM START
# -------------
clear
echo "----------------------------------------------"
echo $K_NAME "Build Script"
echo "----------------------------------------------"
echo ""
echo "----------------------------------------------"
echo "(1) GCC"
echo "(2) Clang"
echo "----------------------------------------------"
read -p "Select a cross compiler: " ccprompt

if [ $ccprompt == "1" ]; then
    CC_NAME=gcc
elif [ $ccprompt == "2" ]; then
    CC_NAME=clang
fi

echo "Using "$CC_NAME"..."

echo ""
echo "----------------------------------------------"
echo "Exynos 8890 family"
echo "(1) herolte"
echo "(2) hero2lte"
echo "(3) ALL"
echo "----------------------------------------------"
read -p "Select device(s) to compile the kernel: " prompt


if [ $prompt == "1" ]; then
    MODEL=herolte
    DEFCONFIG_SPLIT=hero_defconfig
    LOG=$HEROLTE_LOG
    MAIN
elif [ $prompt == "2" ]; then
    MODEL=hero2lte
    DEFCONFIG_SPLIT=hero2_defconfig
    LOG=$HERO2LTE_LOG
    MAIN
elif [ $prompt == "3" ]; then
    MODEL=herolte
    DEFCONFIG_SPLIT=hero_defconfig
    LOG=$HEROLTE_LOG
    echo "All devices will be compiled..."
    MAIN2
    MODEL=hero2lte
    DEFCONFIG_SPLIT=hero2_defconfig
    LOG=$HERO2LTE_LOG
    MAIN
fi


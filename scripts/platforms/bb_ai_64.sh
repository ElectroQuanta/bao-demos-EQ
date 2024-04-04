#!/bin/bash

# ==============================================
# @author: Jose Pires
# @date: 06-10-2023
# @brief: Script to build Bootable Linux image from source
#
# *Requirements*:
# Debian 11.x:
# sudo apt update
# sudo apt install bc bison flex libssl-dev u-boot-tools python3-pycryptodome python3-pyelftools binutils-arm-linux-gnueabihf binutils-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu tree
#
# *Artifacts*:
# We will need the following artifacts to obtain a Linux bootable image:
# 1. Bootloader
# 2. Firmware
# 3. Kernel image
# 4. Device tree and overlays
# 5. extlinux.conf: config file to instruct the bootloader what to load
# 6. Root filesystem
#
# *Structure*:
# The previous artifacts are usually organized into two partitions:
# 1. Boot (FAT16): contains all artifacts, except the root filesystem
# 2. rootfs (ext4): contains the root filesystem
#
# The boot partition tree will be similar to this:
# ```bash
#   # tree <mountPoint>/boot/
#   tree /media/boot/
# ```
#      /media/boot/
#      ├── Image
#      ├── extlinux
#      │   └── extlinux.conf
#      ├── k3-j721e-*.dtb
#      ├── overlays
#      │   └── *.dtbo
#      ├── sysfw.itb
#      ├── tiboot3.bin
#      ├── tispl.bin
#      └── u-boot.img
#
# *Steps*:
# 1. Build bootloader with a patch to build optee properly
# 2. Build kernel with device tree and overlays enabled
# 3. Grab a base linux file system
# 4. Create the extlinux.conf file w/ boot instructions
# 5. To deploy to the SD card, call deploy.sh
# ================================================

PROC_REF="k3-j721e"
KERNEL_VER="5.10.162"

# Set script absolute path
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

export BASH_MAIN=$(realpath "$script_dir/..")
echo "$BASH_MAIN"

# Obtain additional utility functions
source_helper(){
    # local help_script=$1
    source "$1"
    if [ ! $? -eq 0 ]; then
		echo "Could not find helper script $1"
		echo "Aborting..."
		exit
    fi
    print_info "Sourced: $1"
}
# source_helper "$helper_script"
source_helper "$BASH_MAIN/scripts/utils.sh"

# Setting environment
setup_env


# Setup build directories
BUILD_DIR="$BAO_DEMOS_WRKDIR_SRC/bootloader"

KERNEL_DIR="$BUILD_DIR/kernel"
KERNEL_IMG_DIR="$KERNEL_DIR/DEB_IMG"

DTBS_DIR="$KERNEL_IMG_DIR/boot/dtbs/$KERNEL_VER/ti"
OVERLAYS_DIR="$DTBS_DIR/overlays"
CFG_DIR="$BUILD_DIR/extlinux"

ROOTFS_DIR="$BUILD_DIR/rootfs"

YES_NO_OPTS=("yes" "no" "quit")

SD_DEVICE=""
BOOT_PART="BOOT"
ROOTFS_PART="rootfs"
MOUNT_DIR="/run/media/$USER/SDCard"
export BAO_DEMOS_SDCARD="$MOUNT_DIR/$BOOT_PART"


# IMPORTANT: This is a fix of the provided build script, due to linking errors.
# List of packages to install
#packages=("bc" "bison" "flex" "libssl-dev" "u-boot-tools" "python3-pycryptodome" "python3-pyelftools" "binutils-arm-linux-gnueabihf" "binutils-aarch64-linux-gnu gcc-arm-linux-gnueabihf" "gcc-aarch64-linux-gnu" "tree")

PKGS_TI="bc bison flex libssl-dev u-boot-tools python3-pycryptodome python3-pyelftools binutils-arm-linux-gnueabihf binutils-aarch64-linux-gnu gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu tree"



build_ti_fw(){
    if [ -d ./tmp/ti-linux-firmware/ ] ; then
		rm -rf ./tmp/ti-linux-firmware/ || true
    fi

    if [ ! -f ./deploy/ipc_echo_testb_mcu1_0_release_strip.xer5f ] ; then
		print_info "====== TI Linux Firmware ====== "
		mkdir -p ./tmp/ti-linux-firmware/
		print_info ">> Downloading..."
		repo=https://git.ti.com/git/processor-firmware/ti-linux-firmware.git
		git clone -b 08.03.00.003 "$repo" --depth=1 ./tmp/ti-linux-firmware/
		print_info ">> Copying files... "
		cp -v ./tmp/ti-linux-firmware/ti-dm/j721e/ipc_echo_testb_mcu1_0_release_strip.xer5f ./deploy/
		print_info "=================="
    fi
}

build_atf() {

	local spd="$1"


    if [ -d ./tmp/arm-trusted-firmware/ ] ; then
		rm -rf ./tmp/arm-trusted-firmware/ || true
    fi

    if [ ! -f ./deploy/bl31.bin ] ; then
		print_info "====== ATF ====== "
		mkdir -p ./tmp/arm-trusted-firmware/
		print_info ">> Downloading..."

		#branch=bbb.io-08.01.00.006
		branch=master
		repo=https://git.beagleboard.org/beagleboard/arm-trusted-firmware.git

		git clone -b $branch $repo --depth=1 ./tmp/arm-trusted-firmware/

		print_info ">> Building... "
		make -C tmp/arm-trusted-firmware -j4 CROSS_COMPILE=aarch64-linux-gnu- CFLAGS= LDFLAGS= ARCH=aarch64 PLAT=k3 TARGET_BOARD=generic $spd all
		print_info ">> Copying files... "
		cp -v ./tmp/arm-trusted-firmware/build/k3/generic/release/bl31.bin ./deploy/
		print_info "=================="
    fi
}

build_optee(){
    if [ -d ./tmp/optee_os/ ] ; then
		rm -rf ./tmp/optee_os/ || true
    fi

    if [ ! -f ./deploy/tee-pager_v2.bin ] ; then
		print_info "====== TEE ====== "
		print_info ">> Downloading..."
		mkdir -p ./tmp/optee_os/
		git clone -b 08.01.00.005 https://git.beagleboard.org/beagleboard/optee_os.git --depth=1 ./tmp/optee_os/

		######################### Patch
		patch_file "./tmp/optee_os/core/arch/arm/kernel/link.mk" 20 "link-ldflags += --no-warn-rwx-segments\n"
		############################################################

		print_info ">> Building... "
		make -C tmp/optee_os -j4 CROSS_COMPILE=arm-linux-gnueabihf- CFLAGS= LDFLAGS= PLATFORM=k3-j721e CFG_ARM64_core=y ARCH=arm
		
		print_info ">> Copying files... "
		cp -v ./tmp/optee_os/out/arm-plat-k3/core/tee-pager_v2.bin ./deploy/
		print_info "=================="
    fi
}

build_sysfw() {
    if [ -d /tmp/k3-image-gen ] ; then
		rm -rf /tmp/k3-image-gen || true
    fi

    # This tool is intended to be a simple solution to allow users to create an image tree blob (a.k.a. FIT image) comprising a signed System Firmware image as well as the binary configuration artifacts needed to bring up SYSFW as part of the U-Boot SPL startup   
    if [ ! -f ./deploy/sysfw.itb ] ; then
		print_info "====== K3 image gen (SYSFW) ====== "
		print_info ">> Downloading..."

		mkdir -p ./tmp/k3-image-gen/
		git clone -b 08.01.00.006 https://github.com/beagleboard/k3-image-gen --depth=1 ./tmp/k3-image-gen/

		print_info ">> Building... "
		find . -exec touch {} + # Resetting time
		make -C tmp/k3-image-gen/ SOC=j721e CONFIG=evm CROSS_COMPILE=arm-linux-gnueabihf-
		print_info ">> Copying files... "
		cp -v ./tmp/k3-image-gen/sysfw.itb ./deploy/
		print_info "=================="
    fi
}


build_uboot() {
    if [ -d ./tmp/u-boot/ ] ; then
		rm -rf ./tmp/u-boot/ || true
    fi


    if [ ! -f ./deploy/u-boot.img ] ; then
		print_info "====== U-Boot ====== "
		print_info ">> Downloading..."
		mkdir -p ./tmp/u-boot/
		git clone -b v2021.01-ti-08.01.00.006 https://git.beagleboard.org/beagleboard/u-boot.git --depth=1 ./tmp/u-boot/

		if [ ! -f ./deploy/tiboot3.bin ] ; then
			print_info ">> Creating config for tiboot3 (R5)... "

			defconfig=j721e_evm_r5_defconfig
			#print_info "Patching config"
			#patch -i "$BASH_MAIN/r5defconfig.diff" ./tmp/u-boot/configs/$defconfig

			find . -exec touch {} + # Resetting time
			make -C ./tmp/u-boot -j1 O=../r5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $defconfig

			print_info ">> Building... "
			find . -exec touch {} + # Resetting time
			make -C ./tmp/u-boot -j5 O=../r5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
			print_info ">> Copying files..."
			cp -v tmp/r5/tiboot3.bin deploy/
		fi

		print_info ">> Creating config for u-boot (A72)... "
		defconfig=j721e_evm_a72_defconfig
		# print_info "Patching config"
		# patch -i "$BASH_MAIN/a72defconfig.diff" ./tmp/u-boot/configs/$defconfig
		find . -exec touch {} + # Resetting time
		make -C ./tmp/u-boot -j1 O=../a72 ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- $defconfig

		print_info ">> Building... "
		DIR="$PWD"

		# Check if TEE pager exists
		tee_bin=${DIR}/deploy/tee-pager_v2.bin
		tee_cmd="TEE=$tee_bin"
		if [ ! -f "$tee_bin" ]; then
			tee_cmd=""
		fi
		print_info "Building with TEE=$tee_cmd"
		find . -exec touch {} + # Resetting time
		make -C ./tmp/u-boot -j5 O=../a72 ARCH=arm \
			 CROSS_COMPILE=aarch64-linux-gnu- \
			 ATF=${DIR}/deploy/bl31.bin \
			 $tee_cmd	      \
			 DM=${DIR}/deploy/ipc_echo_testb_mcu1_0_release_strip.xer5f

		print_info ">> Copying files... "
		cp -v ./tmp/a72/tispl.bin ./deploy/
		cp -v ./tmp/a72/u-boot.img ./deploy/
		print_info "=================="
	fi
}


######## Bootloader
build_bootloader() {
    print_info "======================================"
    print_info "............... Bootloader ................."
    BOOTLOADER_REPO=https://git.beagleboard.org/beagleboard/beaglebone-ai-64.git
    echo "src: $BOOTLOADER_REPO/sw/bootloader/build.sh"
    ignore_error=false

    # Setup build directories
    create_dir "$BUILD_DIR"
    cd "$BUILD_DIR"
    create_dir "./tmp/"
    create_dir "./deploy/"

    build_ti_fw  # Build Firmware
	spd="" # 
	#spd="SPD=opteed" # 

    build_atf "$spd" # Build ATF (w/ or w/out SPD)
	if [ ! -z "$spd" ]; then # If spd not empty, build optee
		build_optee # Build OPTEE
	fi
    build_sysfw # Build SYSFW
    build_uboot # Build U Boot
    
    print_info ">> Build successful..."

    print_info ">> Deployment tree:"
    tree ./deploy/
    print_info "======================================"
}

######## Kernel
build_kernel() {
    print_info "======================================"
    print_info "............... Kernel ................."
    KERNEL_REPO=https://github.com/beagleboard/linux.git
    git clone "$KERNEL_REPO" "$KERNEL_DIR" --depth=1 -b 5.10-arm64
    # Check for build script
    #BOOT_BUILD_DIR="$BOOT_DIR/sw/bootloader"
    #BOOT_BUILD_SCRIPT="$BOOT_BUILD_DIR/build.sh"
    #if [ -f "$BOOT_BUILD_SCRIPT" ]; then
    #    cd "$BOOT_BUILD_DIR"
    #else
    #    print_error "ERROR: Build script not found...."
    #    exit 1
    #fi
    cd $KERNEL_DIR
    CORES=$(getconf _NPROCESSORS_ONLN)
    export CC=/usr/bin/aarch64-linux-gnu-
    print_info ">> Configuring..."
    make ARCH=arm64 CROSS_COMPILE=${CC} clean
    make ARCH=arm64 CROSS_COMPILE=${CC} bb.org_defconfig
    echo "CONFIG_OF_OVERLAY=y" >> .config
    echo "CONFIG_TFABOOT=y" >> .config
    build_cmd="make -j${CORES} ARCH=arm64 KBUILD_DEBARCH=arm64 CROSS_COMPILE=${CC} bindeb-pkg"
    print_info ">> Building..."
    print_info "$build_cmd"
    eval "$build_cmd"
    mv ../*.deb ./
    #source "$BOOT_BUILD_SCRIPT"
    print_info ">> Build successful..."
    print_info "======================================"
}

extract_kernel_img() {
    print_info "==== Extracting kernel image"
    mkdir -p "$KERNEL_IMG_DIR"
    # kImg=$(ls "$KERNEL_DIR/../linux-image*.deb" 2>&1)
    kImg=$(ls $KERNEL_DIR/linux-image*.deb)

    if [ $? -eq 0 ]; then # success
		if [ "$kImg" = "" ]; then
			print_error "Kernel image NOT built... Aborting..."
			exit 1
		else
			print_info "Kernel image=$kImg..."
			dpkg-deb -x "$kImg" "$KERNEL_IMG_DIR"
		fi
    else
		print_error "Cannot locate kernel image... Aborting..."
		exit 1
    fi


    if [ -d "$OVERLAYS_DIR" ] ; then
		print_info "Overlays built..."
    else
		print_error "Overlays NOT built... Aborting..."
		exit 1
    fi

    if ls $DTBS_DIR/$PROC_REF*.dtb >/dev/null 2>&1; then
		print_info "Device trees built..."
    else
		print_error "Device trees NOT built... Aborting..."
		exit 1
    fi
}

build_rootfs() {
    print_info "======================================"
    print_info "............... Root filesystem ................."
    mkdir -p "$ROOTFS_DIR"
    cd "$ROOTFS_DIR"
    rootfs_file=debian-11.4-minimal-arm64-2022-08-05.tar.xz
    rootfs_location="https://rcn-ee.net/rootfs/eewiki/minfs/$rootfs_file"
	#     https://rcn-ee.com/rootfs/bb.org/testing/2023-05-18/bullseye-minimal-armhf/am57xx-debian-11.7-minimal-armhf-2023-05-18-2gb.img.xz
    #rootfs_location="https://rcn-ee.com/rootfs/bb.org/testing/2023-03-10/bullseye-minimal-arm64/bbai64-debian-11.6-minimal-arm64-2023-03-10-4gb.img.xz"
    # rootfs_file=$(ls *.img.xz)


    print_info ">> Building..."
    wget -c "$rootfs_location"

    tar xf "$rootfs_file"
    print_info ">> Success..."
    print_info "======================================"
}

#build_cfg_file() {
#    print_info "======================================"
#    print_info "............... Building config file ................."
#    mkdir -p "$CFG_DIR"
#    cfg_contents=$(cat <<EOF
#label Linux microSD
#kernel /Image
#append console=ttyS2,115200n8 earlycon=ns16550a,mmio32,0x02800000 root=/dev/mmcblk1p2 ro rootfstype=ext4 rootwait net.ifnames=0
#fdtdir /
#EOF
#		)
#    echo "$cfg_contents" > "$CFG_DIR/extlinux.conf"
#    print_info ">> Success..."
#    print_info "======================================"
#}

build_cfg_file() {

    local kernel_include="$1"
    kernel_location=""

    if [ "$kernel_include" == "1" ]; then
		kernel_location="kernel /Image\n"
    fi
    
    
    print_info "======================================"
    print_info "............... Building config file ................."
    mkdir -p "$CFG_DIR"
    #serial_driver="ns16550a"
    serial_driver="8250"
    uart_addr="0x02800000"
    uart_cfg="115200n8"
    #net_interfaces_disable="net.ifnames=0"
    net_interfaces_disable=""
    cfg_contents=$(cat <<EOF
label Linux microSD
${kernel_location}append console=ttyS2,${uart_cfg} earlycon=${serial_driver},mmio32,${uart_addr} ${net_interfaces_disable}
fdtdir /
EOF
				)
    echo "$cfg_contents" > "$CFG_DIR/extlinux.conf"
    print_info ">> Success..."
    print_info "======================================"
}



# ==============================================
# @author: Jose Pires
# @date: 06-10-2023
# @brief: Script to deploy Bootable Linux image to SD card
#
# *Requirements*:
# 1. Boot artifacts and rootfs previously built, using build.sh
# 2. SD inserted
#
# *Steps*:
# 1. Deploy to the SD card
#  1. Insert the SD card
#  2. Unmount the SD card if automatically mounted
#  3. Partition the SD card
#  2. Format the partitions
#  2. Remount the partitions
#  2. Copy files
#    1. For BOOT partition
#      1. Bootloader and Firmware
#      2. extlinux.conf
#      2. Device tree
#      2. Overlays
#      2. Uncompress and copy the kernel image 
#    2. For rootfs partition
#      1. Uncompress and copy the root filesystem

######## Bootloader
check_requirements() {

    local sd_dev=""
    
    print_info "======================================"
    print_info "............... Checking requirements ................."
    valid_choice=false
    while [ "$valid_choice" = "false"  ]
    do
		print_info "SD Card inserted?"
		get_user_choice "${YES_NO_OPTS[@]}"
		answer_index=$?
		if [ $answer_index -eq 0 ]; then # yes
			valid_choice=true
		else 
			if [ $answer_index -eq 2 ]; then #quit
				print_info "Quitting..."
				exit 1
			fi
		fi
    done

    # List block devices
    lsblk

    print_info ">> Setting SD card partition"
    # Read the user's choice
    read -p "Enter the /dev/sdX partition (full): " answer
    if ls $answer >/dev/null 2>&1; then
		SD_DEVICE="$answer"
		sd_dev="$answer"
		print_info "SD device $answer found..."
		unmount_partitions "$SD_DEVICE"
    else
		print_error "Wrong device... aborting..."
		exit 1
    fi
    print_info "======================================"

	#    echo "$sd_dev"

    # check if it is mounted and unmount
}

unmount_partitions() {
    print_info ">> Unmounting partitions "
    target_device="$1"
    # Check if the target device is mounted
    if mount | grep -q "$target_device"; then
		echo "$target_device is currently mounted."

		# List mounted partitions of the target device
		mounted_partitions=$(mount | grep "$target_device" | awk '{print $1}')

		# Unmount each mounted partition
		for partition in $mounted_partitions; do
            echo "Unmounting $partition..."
            sudo umount "$partition"
		done

		print_info "All partitions of $target_device have been unmounted."
    else
		print_info "$target_device is not currently mounted... Proceeding..."
    fi
}

format_partitions() {
    print_info "===================================="
    print_info "............... Format partitions ................."

    target_device="$1"
    sudo sfdisk "$target_device" <<-__EOF__
1M,128M,0xC,*
129M,,,-
__EOF__

    print_info ">> Partition 1: $BOOT_PART"
    sudo mkfs.vfat -F 16 "${target_device}1" -n "$BOOT_PART"
    print_info ">> Partition 2: $ROOTFS_PART"
    sudo mkfs.ext4 "${target_device}2" -L "$ROOTFS_PART"
    lsblk
    print_info "======================================"
}

mount_partitions() {
    target_device="$1"
    print_info ">> Mounting partitions"
    sd1="$MOUNT_DIR/$BOOT_PART"
    sd2="$MOUNT_DIR/$ROOTFS_PART"
    sudo mkdir -p "$sd1"
    sudo mkdir -p "$sd2"
    sudo mount "${target_device}1" "$sd1"
    sudo mount "${target_device}2" "$sd2"
    lsblk
}

copy_files_wrkdir() {
    target_device="$1"
    sd1="$BAO_DEMOS_WRKDIR_PLAT"

    print_info ">> Copying files..."
    cp -vf "$BUILD_DIR/deploy/sysfw.itb" "$sd1"
    cp -vf "$BUILD_DIR/deploy/tiboot3.bin" "$sd1"
    cp -vf "$BUILD_DIR/deploy/tispl.bin" "$sd1"
    cp -vf "$BUILD_DIR/deploy/u-boot.img" "$sd1"

    print_info ">> Device tree"
    cp -v $DTBS_DIR/$PROC_REF*.dtb "$sd1"

    print_info ">> Overlays"
    cp -vr "$OVERLAYS_DIR" "$sd1"

    print_info ">> Configuration file"
    cp -vr "$CFG_DIR" "$sd1"
    sync

    print_info ">> Kernel image"
    #cat "$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}" | gunzip -d > "$KERNEL_IMG_DIR/boot/Image"
    kImg="$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}"
    # echo "$kImg"
    gunzip -vc '$kImg' > '$sd1'/Image
    
    #sudo sh -c "gunzip -vc '$kImg' > '$sd1'/Image"
    tree "$sd1"
    
}

copy_files_sdCard() {
    target_device="$1"
    sd1="$MOUNT_DIR/$BOOT_PART"
    sd2="$MOUNT_DIR/$ROOTFS_PART"

    print_info "======================================"
    print_info "............... Erasing files ................."
    sudo rm -vrf $sd1/*
    #sudo rm -vrf "$sd2/*"

    print_info "............... Copying files ................."

    print_info "==== Partition 1: $BOOT_PART"

    print_info ">> Bao"
	#    sudo cp -v -rf $BAO_DEMOS_WRKDIR_PLAT/firmware/boot/* $BAO_DEMOS_SDCARD
	#    sudo cp -v $BAO_DEMOS_WRKDIR_PLAT/bl31.bin $BAO_DEMOS_SDCARD
	#    sudo cp -v $BAO_DEMOS_WRKDIR_PLAT/u-boot.bin $BAO_DEMOS_SDCARD
    #sudo cp -v $BAO_DEMOS_WRKDIR_IMGS/bao.bin $BAO_DEMOS_SDCARD
    sudo cp -v $BAO_DEMOS_WRKDIR_IMGS/* $BAO_DEMOS_SDCARD

    print_info ">> Bootloader and firmware"
    #sudo cp -vf "$BOOT_BUILD_DIR/deploy/sysfw.itb" "$sd1"
    #sudo cp -vf "$BOOT_BUILD_DIR/deploy/tiboot3.bin" "$sd1"
    #sudo cp -vf "$BOOT_BUILD_DIR/deploy/tispl.bin" "$sd1"
    #sudo cp -vf "$BOOT_BUILD_DIR/deploy/u-boot.img" "$sd1"
    sudo cp -vf "$BAO_DEMOS_WRKDIR_PLAT/sysfw.itb" "$sd1"
    sudo cp -vf "$BAO_DEMOS_WRKDIR_PLAT/tiboot3.bin" "$sd1"
    sudo cp -vf "$BAO_DEMOS_WRKDIR_PLAT/tispl.bin" "$sd1"
    sudo cp -vf "$BAO_DEMOS_WRKDIR_PLAT/u-boot.img" "$sd1"
    sync

    print_info ">> Device tree"
    sudo cp -v $BAO_DEMOS_WRKDIR_PLAT/$PROC_REF*.dtb "$sd1"
    sync

    print_info ">> Overlays"
    sudo cp -vr "$BAO_DEMOS_WRKDIR_PLAT/overlays" "$sd1"
    sync

    print_info ">> Configuration file"
    sudo cp -vr "$BAO_DEMOS_WRKDIR_PLAT/extlinux" "$sd1"
    sync

    print_info ">> Kernel image"
    #cat "$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}" | gunzip -d > "$KERNEL_IMG_DIR/boot/Image"
	#    kImg="$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}"
	# echo "$kImg"
    #sudo sh -c "gunzip -vc '$kImg' > '$sd1'/Image"
    sudo cp -v "$BAO_DEMOS_WRKDIR_PLAT/Image" "$sd1"
    sync

	#    print_info "==== Partition 2: $ROOTFS_PART"
	#    sudo tar xfvp "$ROOTFS_DIR"/debian-*-*-arm64-*/arm64-rootfs-*.tar -C "$sd2"
    #    sync

	#      1. Bootloader and Firmware
	#      2. extlinux.conf
	#      2. Device tree
	#      2. Overlays
	#      2. Uncompress and copy the kernel image 
	#    2. For rootfs partition
    #      1. Uncompress and copy the root filesystem

	# PROC_REF="k3-j721e"
	# KERNEL_VER="5.10.162"
	# 
	# # Setup build directories
	# BUILD_DIR="$BASH_MAIN/build"
	# BOOT_DIR="$BUILD_DIR/boot"
	# BOOT_BUILD_DIR="$BOOT_DIR/sw/bootloader"
	# BOOT_BUILD_SCRIPT="$BOOT_BUILD_DIR/build.sh"
	# KERNEL_DIR="$BUILD_DIR/kernel"
	# KERNEL_IMG_DIR="$KERNEL_DIR/DEB_IMG"
	# DTBS_DIR="$KERNEL_IMG_DIR/boot/dtbs/$KERNEL_VER/ti"
	# OVERLAYS_DIR="$DTBS_DIR/overlays"
	# ROOTFS_DIR="$BUILD_DIR/rootfs"
	#CFG_DIR="$BUILD_DIR/extlinux"
	# 
	# YES_NO_OPTS=("yes" "no" "quit")
	# 
	# SD_DEVICE=""
	# BOOT_PART="BOOT"
	# ROOTFS_PART="rootfs"
	# MOUNT_DIR="/run/media/$USER/SDCard"

    tree "$sd1"
}

print_next_steps() {

    local mmc_dev="1"
    local load_addr="0x80000000"
    read -r -d '' my_string <<EOF
## 4) Setup board
1. Insert the sd card in the board's sd slot.

2. Connect to the BeagleBone AI-64's UART using a USB-to-TTL adapter to connect to the UART JST connector pins.

3. Use a terminal application such as "screen". For example:
"screen /dev/ttyUSB0 115200"

4. Hold the BOOT button and power the board.

5. Release the button after U-Boot or the kernel finish loading.


## 5) Run u-boot commands

1. Quickly press any key to skip autoboot. If not possibly press "ctrl-c" until 
you get the u-boot prompt.

2. Check the MMMC device where bao.bin is loaded
"fatls mmc $mmc_dev"
where mmc_dev should be a number between 0 and the number of MMC devices - 1

3. Then load the bao image, and jump to it:

"fatload mmc $mmc_dev bao.bin; go $load_addr"

You should see the firmware, bao and its guests printing on the UART.

At this point, depending on your demo, you might be able connect to one of the 
guests via ssh by connecting to the board's ethernet RJ45 socket.
EOF

    echo "$my_string"

}

############################# Functions to be called externally ################
build_bb_boot(){
    # Check dependencies
    check_deps "$PKGS_TI"

    # Build bootloader & firmware
    build_bootloader

    # Build kernel
    #	build_kernel
    #	extract_kernel_img

    #	# Build root filesystem
    #	build_rootfs
    #
    # Build config (dont include kernel)
    build_cfg_file 0

    copy_files_wrkdir
}

sdcard_deploy() {
    ignore_error=false

    print_info ">> SD card deploy with ATF and U-Boot"

    # Check requirements
    #sd_dev=$(check_requirements)
    check_requirements
    #if [ "$sd_dev" == "" ]; then
    #	print_error "Could not find SD card... Aborting"
    #	exit 1
    #fi

    mount_partitions "$SD_DEVICE"

    # Check if the user wants to format partitions
    sudo parted "$SD_DEVICE" print # list partitions
    print_info "Format partitions?"
    get_user_choice "${YES_NO_OPTS[@]}"
    answer_index=$?
    if [ $answer_index -eq 0 ]; then # yes
		format_partitions "$SD_DEVICE"
		mount_partitions "$SD_DEVICE"
    else 
		if [ $answer_index -eq 2 ]; then #quit
			print_info "Quitting..."
			exit 1
		fi
    fi

    copy_files_sdCard "$SD_DEVICE"

    unmount_partitions "$SD_DEVICE"

    print_info "SUCCESS: You can now eject your SD card."
    print_info "================== Next steps ================== "
    print_next_steps

}



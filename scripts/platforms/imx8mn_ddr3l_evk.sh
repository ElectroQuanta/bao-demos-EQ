#!/bin/bash

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


SD_DEVICE=""
BOOT_PART="BOOT"
ROOTFS_PART="rootfs"
#MOUNT_DIR="/run/media/$USER/SDCard"
MOUNT_DIR="$BASH_MAIN/SDCard"

YES_NO_OPTS=("yes" "no" "quit")

DEBUG_ATF=0


export BAO_DEMOS_MKIMG="$BAO_DEMOS_WRKDIR_SRC/imx-mkimage"
export BAO_DEMOS_MKIMG_IMX="$BAO_DEMOS_WRKDIR_SRC/imx-mkimage/iMX8M"
export BAO_DEMOS_VM_SF="$HOME/VMs/SFUb22"

#export BAO_DEMOS_SDCARD_DEV=/dev/mmcblk0 # extracted from lsblk
export BAO_DEMOS_SDCARD="$MOUNT_DIR/$BOOT_PART"
#export ATF_LOAD_ADDR=0x960000

#mkdir -p "$BAO_DEMOS_MKIMG"

VERSION_BRANCH=lf-6.1.55-2.2.0

uboot_build() {
    # retrieve cfg
    #local cfg=$1
    
    export BAO_DEMOS_UBOOT="$BAO_DEMOS_WRKDIR_SRC/uboot-imx"

    print_info "========================== "
    print_info "...................... U-Boot ................... "

    # Cloning repo
    if [ "$1" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_UBOOT" || true
    fi

    if [ ! -d "$BAO_DEMOS_UBOOT" ]; then
	echo "Rebuilding...."
	git clone https://github.com/nxp-imx/uboot-imx.git $BAO_DEMOS_UBOOT\
	    --branch="$VERSION_BRANCH" --depth=1
    fi

    # Clean the build
    make -C "$BAO_DEMOS_UBOOT" clean || true
    
    # Make config
    print_info ">> Creating config..."
    make -C "$BAO_DEMOS_UBOOT" imx8mn_ddr3l_evk_defconfig

    #export ATF_LOAD_ADDR=0x960000

    # Building
    ignore_error=true
    print_info ">> Building..."
    make_cmd="make -C $BAO_DEMOS_UBOOT -j$(nproc)"
    run_make_cmd "$make_cmd"
    ignore_error=false
}

atf_build() {
    export BAO_DEMOS_ATF="$BAO_DEMOS_WRKDIR_SRC/atf"

    print_info "=================================================="
    print_info "...................... ATF ................... "

    # Cloning repo
    if [ "$1" = "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_ATF" || true
    fi

    if [ ! -d "$BAO_DEMOS_ATF" ]; then
	echo "Rebuilding...."
	# git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/ $BAO_DEMOS_ATF --branch=v2.10
	git clone https://github.com/nxp-imx/imx-atf.git $BAO_DEMOS_ATF\
	    --branch="$VERSION_BRANCH"
    fi

    # Clean the build
    make -C "$BAO_DEMOS_ATF" distclean || true

#    git clone https://github.com/nxp-imx/imx-atf.git $BAO_DEMOS_ATF\
#	--branch=imx_5.4.70_2.3.0 --depth=1
    cd "$BAO_DEMOS_ATF"
    ignore_error=true
    log_lvl=20
    print_info ">> Building..."
    #make_cmd="make -C $BAO_DEMOS_ATF -j$(nproc) PLAT=imx8mn bl31"
    make_cmd="compiledb \
make -C $BAO_DEMOS_ATF -j$(nproc) bl31 PLAT=imx8mn DEBUG=$DEBUG_ATF CFLAGS=-Os \
LOG_LEVEL=$log_lvl"
    run_make_cmd "$make_cmd"
    cd "$BASH_MAIN"
    ignore_error=false
}

# Firmware
fw_build(){
    print_info "=================================================="
    print_info "................. Firmware: DDR + HDMI ................... "

    # see https://www.nxp.com/docs/en/release-note/IMX_LINUX_RELEASE_NOTES.pdf
    # BSP and multimedia standard packages
    FW_VER="8.22"
    FW_IMX="firmware-imx-$FW_VER"
    export BAO_DEMOS_FW="$BAO_DEMOS_WRKDIR_SRC/$FW_IMX"


    # Cloning repo
    if [ "$1" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_FW" || true
    fi

    if [ ! -d "$BAO_DEMOS_FW" ]; then
	echo "Rebuilding...."
	wget -P $BAO_DEMOS_WRKDIR_SRC\
	     https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/$FW_IMX.bin
	cd $BAO_DEMOS_WRKDIR_SRC # binary will extract to current path
	chmod +x ./$FW_IMX.bin
	./$FW_IMX.bin
	cd $BASH_MAIN # return to main 
    fi

    echo "Nothing to do..."

}

# imx-mkimage
mkimg_build(){
    print_info "=================================================="
    print_info "................. IMX MKIMG: creating image ............... "
    
    # Cloning repo
    if [ "$1" == "deep" ] ; then 
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_MKIMG" || true
    fi

    if [ ! -d "$BAO_DEMOS_MKIMG" ]; then
	# git clone https://github.com/nxp-imx/imx-mkimage $BAO_DEMOS_MKIMG\
	#     --branch lf-6.1.55_2.2.0 --depth 1
	git clone https://github.com/nxp-imx/imx-mkimage $BAO_DEMOS_MKIMG\
	    --branch "$VERSION_BRANCH" --depth 1
    fi

    cp -v $BAO_DEMOS_UBOOT/tools/mkimage $BAO_DEMOS_MKIMG_IMX/mkimage_uboot
    cp -v $BAO_DEMOS_UBOOT/spl/u-boot-spl.bin $BAO_DEMOS_MKIMG_IMX
    cp -v $BAO_DEMOS_UBOOT/u-boot-nodtb.bin $BAO_DEMOS_MKIMG_IMX
    cp -v $BAO_DEMOS_UBOOT/arch/arm/dts/imx8mn-ddr3l-evk.dtb $BAO_DEMOS_MKIMG_IMX/imx8mn-ddr3l-val.dtb
    cp -v $BAO_DEMOS_ATF/build/imx8mn/release/bl31.bin $BAO_DEMOS_MKIMG_IMX

    cp -v $BAO_DEMOS_FW/firmware/hdmi/cadence/signed_hdmi_imx8m.bin $BAO_DEMOS_MKIMG_IMX

    cp -v $BAO_DEMOS_FW/firmware/ddr/synopsys/ddr3_dmem_1d.bin $BAO_DEMOS_MKIMG_IMX/ddr3_dmem_1d_201810.bin
    cp -v $BAO_DEMOS_FW/firmware/ddr/synopsys/ddr3_imem_1d.bin $BAO_DEMOS_MKIMG_IMX/ddr3_imem_1d_201810.bin

    # Build
    print_info ">> Building..."
    cd $BAO_DEMOS_MKIMG
    make -C $BAO_DEMOS_MKIMG clean
    ignore_error=true
# Parts w/o SCU
# 	  flash_ddr3l_val          - DisplayPort FW + u-boot spl
# 	  flash_ddr3l_val_no_hdmi  - u-boot spl
# 	  flash_hdmi_spl_uboot     - HDMI FW + u-boot spl
# 	  flash_dp_spl_uboot       - DisaplayPort FW + u-boot spl
# 	  flash_spl_uboot          - u-boot spl
    #make_cmd="make -C $BAO_DEMOS_MKIMG -j${nproc} SOC=iMX8MN flash_ddr3l_val_no_hdmi"
    make_cmd="make -C $BAO_DEMOS_MKIMG -j${nproc} SOC=iMX8MN flash_ddr3l_val"
    run_make_cmd "$make_cmd"
    ignore_error=false

    cd $BASH_MAIN

    # Copying bin to image dir
    print_info "====== Copying flash.bin into the final image directory"
    ignore_error=false
    cp -v "$BAO_DEMOS_MKIMG_IMX/flash.bin" "$BAO_DEMOS_WRKDIR_IMGS"
    print_info "======================================"
}

build_boot(){
    local bt="$1"
    uboot_build "$bt"
    atf_build "$bt"
    fw_build "$bt"
    mkimg_build "$bt"
}

copy_files_wrkdir() {
    target_device="$1"
    sd1="$BAO_DEMOS_WRKDIR_IMGS"

    print_info ">> Copying files..."
    cp -v "$BAO_DEMOS_MKIMG_IMX/flash.bin" "$sd1"
    
    #print_info ">> Device tree"
    #cp -v $DTBS_DIR/$PROC_REF*.dtb "$sd1"

    #print_info ">> Overlays"
    #cp -vr "$OVERLAYS_DIR" "$sd1"

    #print_info ">> Configuration file"
    #cp -vr "$CFG_DIR" "$sd1"
    #sync

    #print_info ">> Kernel image"
    ##cat "$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}" | gunzip -d > "$KERNEL_IMG_DIR/boot/Image"
    #kImg="$KERNEL_IMG_DIR/boot/vmlinuz-${KERNEL_VER}"
    ## echo "$kImg"
    #gunzip -vc '$kImg' > '$sd1'/Image
    
    #sudo sh -c "gunzip -vc '$kImg' > '$sd1'/Image"
    tree "$sd1"
    
}


check_requirements() {
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
	print_info "SD device $answer found..."
	unmount_partitions "$SD_DEVICE"
    else
	print_error "Wrong device... aborting..."
	exit 1
    fi
    print_info "======================================"

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

create_partition_fdisk(){
    # This function creates three partitions
    # (see Linux User Guide (IMXLUG) - Table 1: Image Layout):
    # 
    # 1) RAW: Starting at sector 0x8000 and ending at sector 0x9F8000.
    #  This contains the bootloader and does not need to be created
    #  The bootloader is copied using dd
    # 2) FAT: Starting at sector 0xA00000 with a size of 500 MB (bootable flag is set).
    #  Contains the boot partition (FAT filesystem)
    # 3) EXT4: Starting at sector 0x25800000 and extending to the end of the disk.
    #  Contains the root filesystem (EXT4 filesystem)
    
# Define the disk device
disk_device="$1"  # Replace sdX with your actual disk device

# Table 1 layout
# Bootloader (RAW partition) - should be copied using fdisk
#raw_start_sectors=64
#raw_size_sectors=20416
# FAT32 partition (boot partition)
fat_start_sectors=20480
fat_size=500M
# Root partition
ext4_start_sectors=1228800

    print_info "====== Create Partition"
    sudo fdisk "$disk_device" <<EOF
o
n
p
1
$fat_start_sectors
+${fat_size}
t
0c
a
n
p
2
$ext4_start_sectors

p
w
EOF

    print_info "=================================================="
}

byte2sectors(){
    local bytes_hex="$1"
    
    local sector_size=512
# Perform the division and round up to the nearest integer
    local sectors_nr=$((bytes_hex / sector_size))

    echo "$sectors_nr"
}

create_partition_sfdisk() {

# This function creates three partitions
# (see Linux User Guide (IMXLUG) - Table 1: Image Layout):
# 
# RAW: Starting at sector 0x8000 and ending at sector 0x9F8000.
# FAT: Starting at sector 0xA00000 with a size of 500 MB (bootable flag is set).
# EXT4: Starting at sector 0x25800000 and extending to the end of the disk.

    
# Define the disk device
disk_device="$1"  # Replace sdX with your actual disk device

# Calculate the sizes in sectors based on the given byte sizes
# 1 sector is 512 bytes

# RAW partition
raw_start=0x8000
raw_size=0x9F8000

# FAT partition
fat_start=0xA00000
fat_size=500M

# EXT4 partition
ext4_start=0x25800000

# Convert byte addresses to sectors
raw_start_addr_sectors=$(byte2sectors $raw_start)
fat_start_addr_sectors=$(byte2sectors $fat_start)
ext4_start_addr_sectors=$(byte2sectors $ext4_start)

#raw_start_addr_sectors=$((raw_start / 512))
#fat_start_addr_sectors=$((fat_start / 512))
#ext4_start_addr_sectors=$((ext4_start / 512))

# Convert byte sizes to sectors
raw_size_sectors=$(byte2sectors $raw_size)
fat_size_bytes=$((500*1024*1024))
fat_size_sectors=$(byte2sectors $fat_size_bytes)

#echo "raw_start_addr_sectors $raw_start_addr_sectors"
#echo "fat_start_addr_sectors $fat_start_addr_sectors"
#echo "ext4_start_addr_sectors $ext4_start_addr_sectors"
#echo "raw_size_sectors $raw_size_sectors"
#echo "fat_size_sectors $fat_size_sectors"

# Create the partition table with sfdisk
# sudo sfdisk "$disk_device" << EOF
# $raw_start_addr_sectors,$raw_size_sectors,*
# $fat_start_addr_sectors,$fat_size_sectors,c
# $ext4_start_addr_sectors,,
# EOF


# Create the partition table with sfdisk (2 partitions only)
sudo sfdisk "$disk_device" << EOF
$fat_start_addr_sectors,$fat_size_sectors,c
$ext4_start_addr_sectors,,
EOF

# Print the updated partition table
sudo sfdisk --list "$disk_device"

    print_info "=================================================="
}

format_partition() {
    local target_partition="${1}1"
    # Format partitions
    print_info "==== Format partition"
    sudo mkfs.vfat -v "$target_partition" -n BOOT
    print_info "=================================================="
}

copy_files() {
    target_device="$1"
    BAO_DEMOS_SDCARD=$target_device

    print_info "======================================"
    print_info "............... Copying files ................."


    print_info ">> Bootloader"
    imx_offset=32 # see iMX Linux User Guide
    test -e $BAO_DEMOS_SDCARD &&\
	sudo dd if=$BAO_DEMOS_WRKDIR_IMGS/flash.bin\
	     of=$BAO_DEMOS_SDCARD bs=1k seek=$imx_offset conv=notrunc || echo Failed flashing sd card!

    sync

    print_info ">> Mounting partitions"

    sd1="$MOUNT_DIR/$BOOT_PART"
    target_partition="${target_device}1"

    mkdir -p "$sd1"
    sudo mount -v "$target_partition" "$sd1"
    lsblk

    print_info "==== Partition 1: $BOOT_PART"
    print_info ">> Erasing "
    sudo rm -vrf $sd1/*
    
    print_info ">> Copying images"
    sudo cp -vr $BAO_DEMOS_WRKDIR_IMGS/* $sd1
    #sudo cp -v $BAO_DEMOS_WRKDIR_IMGS/baremetal.bin $sd1

    tree $sd1

    sync
}

print_next_steps() {
    local MMC_DEV=1
    local RAM1_ADDR=0x40200000
    read -r -d '' my_string <<EOF
## 4) Setup board
Insert the sd card in the board's sd slot.

Connect to the Raspberry Pi's UART using a USB-to-TTL adapter to connect to the
Raspberry Pi's GPIO header UART pins. Use a terminal application such as 
"screen". For example:

"screen /dev/ttyUSB1 115200"

Turn on/reset your board.


## 5) Run u-boot commands

Quickly press any key to skip autoboot. If not possibly press "ctrl-c" until 
you get the u-boot prompt. Then load the bao image, and jump to it:

fatload mmc \$MMC_DEV \$RAM1_ADDR bao.bin; go \$RAM1_ADDR

where:
- \$MMC_DEV is given by mmc list (check what is SD card)
- \$RAM1_ADDR is provided in the platform description 

Example:
"fatload mmc $MMC_DEV $RAM1_ADDR bao.bin; go $RAM1_ADDR"


You should see the firmware, bao and its guests printing on the UART.

At this point, depending on your demo, you might be able connect to one of the 
guests via ssh by connecting to the board's ethernet RJ45 socket.
EOF

    echo "$my_string"

}

sdcard_deploy() {
    ignore_error=false

    print_info ">> SD card deploy with ATF and U-Boot"

    check_requirements

    print_info "Format partitions?"
    get_user_choice "${YES_NO_OPTS[@]}"
    answer_index=$?
    case "$answer_index" in 
	0) # yes
	    #create_partition_sfdisk "$SD_DEVICE"
	    create_partition_fdisk "$SD_DEVICE"
	    format_partition "$SD_DEVICE"
	    ;;
	1) # no
	    ;;
	*)
	    print_info "Quitting..."
	    exit 1
    esac


    # Copy files
    copy_files "$SD_DEVICE"

    unmount_partitions "$SD_DEVICE"

    print_info "SUCCESS: You can now eject your SD card."
    print_info "================== Next steps ================== "
    print_next_steps

}

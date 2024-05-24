#!/bin/bash
# src: https://github.com/bao-project/bao-demos/blob/master/platforms/rpi4/README.md

SD_DEVICE=""
BOOT_PART="BOOT"
ROOTFS_PART="rootfs"
#MOUNT_DIR="/run/media/$USER/SDCard"
MOUNT_DIR="$BASH_MAIN/SDCard"

YES_NO_OPTS=("yes" "no" "quit")

#export BAO_DEMOS_SDCARD_DEV=/dev/mmcblk0 # extracted from lsblk
export BAO_DEMOS_SDCARD="$MOUNT_DIR/$BOOT_PART"
export BAO_DEMOS_FW="$BAO_DEMOS_WRKDIR_PLAT"/firmware
export BAO_DEMOS_UBOOT="$BAO_DEMOS_WRKDIR_SRC"/u-boot
export BAO_DEMOS_ATF="$BAO_DEMOS_WRKDIR_SRC"/arm-trusted-firmware

get_rpi4_fw() {
	print_info "====== Get RPI4 firmware"
	repo_url="https://github.com/raspberrypi/firmware.git"
	firmware_version="1.20240424" # FIX: latest
	#	firmware_version="1.20240306" # FIX: https://github.com/bao-project/bao-demos/commit/3833f5cbdf27b1c730132d745c4e4f362f168976
	# firmware_version="1.20230405" # withdrawn from rpi4/make.mk (HANGS)

	if [ ! -d "$BAO_DEMOS_FW" ]; then
		echo "Rebuilding firmware branch = $firmware_version...."
		git clone "$repo_url" "$BAO_DEMOS_FW" \
			--depth 1 --branch "$firmware_version"
		git submodule update --init --recursive
		git submodule update --remote --recursive
	fi
}

uboot_build() {
	# retrieve cfg
	local cfg=$1

	print_info "========================== "
	print_info "...................... Building U-Boot ................... "
	# Cloning repo
	repo_url="https://github.com/u-boot/u-boot.git"
	release_tag="v2024.04"
	#	release_tag="v2022.10"

	if [ ! -d "$BAO_DEMOS_UBOOT" ]; then
		echo "Rebuilding branch = $release_tag..."
		git clone "$repo_url" "$BAO_DEMOS_UBOOT" \
			--depth 1 --branch "$release_tag"
	fi

	# Make config
	print_info ">> Creating config..."
	make -C "$BAO_DEMOS_UBOOT" "$cfg"

	# Building
	ignore_error=true
	print_info ">> Building..."
	make_cmd="make -C $BAO_DEMOS_UBOOT -j$(nproc)"
	run_make_cmd "$make_cmd"

	# Copying bin to image dir
	print_info "====== Copying the U-Boot binary into the final image directory"
	ignore_error=false
	cp -v "$BAO_DEMOS_UBOOT/u-boot.bin" "$BAO_DEMOS_WRKDIR_PLAT"
	print_info "======================================"
}

atf_build() {
	print_info "=================================================="
	print_info "...................... Building ATF ................... "

	# Cloning repo
	repo_url="https://github.com/ARM-software/arm-trusted-firmware.git"
	release_tag="lts-v2.10.4"

	# repo_url="https://github.com/bao-project/arm-trusted-firmware.git"
	# release_tag="bao/demo"

	if [ ! -d "$BAO_DEMOS_ATF" ]; then
		echo "Rebuilding ATF branch = $release_tag"
		#    "$BAO_DEMOS_ATF" --branch "$branch" --depth 1
		git clone "$repo_url" "$BAO_DEMOS_ATF" \
			--branch "$release_tag" --depth 1
	fi

	make -C "$BAO_DEMOS_ATF" PLAT=rpi4

	# copy image to the platform's working directory
	cp -v "$BAO_DEMOS_ATF/build/rpi4/release/bl31.bin" \
		"$BAO_DEMOS_WRKDIR_PLAT"
}

check_requirements() {
	print_info "======================================"
	print_info "............... Checking requirements ................."
	valid_choice=false
	while [ "$valid_choice" = "false" ]; do
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
	read -rp "Enter the /dev/sdX partition (full): " answer
	if ls "$answer" >/dev/null 2>&1; then
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

create_partition_fdisk() {
	#sudo fdisk /dev/mmcblk0
	#```
	#
	#Then run the commands:
	#
	#* `o` to create a new empty DOS partition table
	#* `n` to create a new partition. Select the following options:
	#    *  `p` to make it a primary partition
	#    *  the automatically assigned partition number by pressing `return`
	#    *  `16384` (this gap is needed for some of the selected boards)
	#    *  the max default size by pressing `return`
	#    *  if it asks you to remove the file system signature press `y`
	#* `a` to make the partition bootable
	#* `t` to set the partition type:
	#    * type `c` for W95 FAT32 (LBA)
	#* `w` to write changes and exit

	# Creating a primary partition with specific characteristics, such as a 16384-sector gap, bootable flag, and partition type, typically requires going through the interactive `fdisk` interface or scripting it as you've shown earlier. There isn't a more compact or single `fdisk` command that covers all these steps directly.

	# The reason for this is that `fdisk` is an interactive tool designed to prevent accidental data loss. When working with partitioning, it's essential to confirm your actions at each step, which is why `fdisk` requires user interaction.
	#
	# While you can script these actions as shown earlier, the interaction is still happening behind the scenes to ensure the user is aware of the changes being made to the disk.
	#
	# So, in summary, while you can script the `fdisk` commands to automate the process, there isn't a single, more compact `fdisk` command to directly create a primary partition with these specific characteristics because `fdisk` is inherently interactive for safety reasons.

	local target_device="$1"
	print_info "====== Create Partition"

	# echo -e "o\nn\np\n\n16384\n\na\nt\nc\nw\n" | sudo fdisk "$target_device"

	# Table 1 layout
	# Bootloader (RAW partition) - should be copied using fdisk
	#raw_start_sectors=64
	#raw_size_sectors=20416
	# FAT32 partition (boot partition)
	fat_start_sectors=16384
	fat_size=500M
	# Root partition
	ext4_start_sectors=1228800

	# Remove any vfat signatures that may exist
	sudo wipefs -a "$target_device"1
	sudo wipefs -a "$target_device"2

	sudo fdisk "$target_device" <<EOF
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

create_partition_sfdisk() {
	# Yes, you can use sfdisk to create partitions programmatically, which can be more suitable for automation compared to fdisk. You can specify the partition layout in a script or a text file and then use sfdisk to apply it. Here's how you can create a primary partition with a 16384 sector gap, make it bootable, and set the partition type to W95 FAT32 (LBA) using sfdisk:
	#
	#     Create a text file (e.g., partition_layout.txt) with the following content:
	#
	#     makefile
	#
	# label: dos
	# label-id: 0x12345678
	# device: /dev/mmcblk0
	# unit: sectors
	#
	# /dev/mmcblk0p1 : start= 16384, size=, type=0xc, bootable
	#
	#     label: dos: Specifies that you want to create a partition table in DOS format.
	#     label-id: 0x12345678: You can set a unique label ID if needed.
	#     device: /dev/mmcblk0: Replace /dev/mmcblk0 with your actual device.
	#     unit: sectors: Specifies that you're working with sectors.
	#
	# /dev/mmcblk0p1 : start= 16384, size=, type=0xc, bootable defines the first partition:
	#
	#     start= 16384: Indicates a 16384 sector gap.
	#     size=: The size will be automatically calculated to use the remaining space on the device.
	#     type=0xc: Sets the partition type to W95 FAT32 (LBA).
	#     bootable: Marks the partition as bootable.
	#
	# Apply the partition layout using sfdisk:
	#
	# bash
	#
	# sudo sfdisk /dev/mmcblk0 < partition_layout.txt
	#
	# Make sure to replace /dev/mmcblk0 with your actual device.

	local target_partition="$1"

	print_info "====== Create Partition"
	sudo sfdisk "$target_partition" <<EOF
label: dos
label-id: 0x12345678
device: /dev/mmcblk0
unit: sectors

${target_partition} : start= 16384, size=, type=0xc, bootable
EOF

	print_info "=================================================="
}

format_partition() {
	local target_partition="${1}1"
	# Format partitions
	print_info "==== Format partition"
	sudo mkfs.fat -v "$target_partition" -n BOOT
	print_info "=================================================="
}

copy_files() {
	target_device="$1"

	print_info "======================================"
	print_info "............... Copying files ................."
	print_info ">> Mounting partitions"

	sd1="$MOUNT_DIR/$BOOT_PART"
	target_partition="${target_device}1"

	mkdir -p "$sd1"
	sudo mount "$target_partition" "$sd1"
	lsblk

	print_info "==== Partition 1: $BOOT_PART"
	print_info "Erasing disk..."
	sudo rm -vrf "$sd1"/*

	print_info ">> Bootloader and firmware"

	# Copy firmware
	sudo cp -vrf "$BAO_DEMOS_WRKDIR_PLAT"/firmware/boot/* "$BAO_DEMOS_SDCARD"
	# Copy configuration txt
	sudo cp -v "$BAO_DEMOS/platforms/rpi4/config.txt" "$BAO_DEMOS_SDCARD"
	# Copy $DEMO binaries (linux.bin, freertos.bin, bao.bin)
	sudo cp -vr "$BAO_DEMOS_WRKDIR_PLAT/$DEMO"/* "$BAO_DEMOS_SDCARD"
	# Copy Bootloader binaries(bl31.bin, u-boot.bin)
	sudo cp -v "$BAO_DEMOS_WRKDIR_PLAT"/* "$BAO_DEMOS_SDCARD"
	# sudo cp -v $BAO_DEMOS_WRKDIR_PLAT/u-boot.bin $BAO_DEMOS_SDCARD
	# sudo cp -v $BAO_DEMOS_WRKDIR_IMGS/bao.bin $BAO_DEMOS_SDCARD
}

print_next_steps() {

	read -r -d '' my_string <<EOF
## 4) Setup board
Insert the sd card in the board's sd slot.

Connect to the Raspberry Pi's UART using a USB-to-TTL adapter to connect to the
Raspberry Pi's GPIO header UART pins. Use a terminal application such as 
"screen". For example:

"screen /dev/ttyUSB0 115200"

Turn on/reset your board.


## 5) Run u-boot commands

Quickly press any key to skip autoboot. If not possibly press "ctrl-c" until 
you get the u-boot prompt. Then load the bao image, and jump to it:

"fatload mmc 0 0x200000 bao.bin; go 0x200000"

You should see the firmware, bao and its guests printing on the UART.

At this point, depending on your demo, you might be able connect to one of the 
guests via ssh by connecting to the board's ethernet RJ45 socket.
EOF

	echo "$my_string"

}

build_bootloader() {

	if [ "$1" == "deep" ]; then
		echo "Removing previous build..."
		rm -rf "$BAO_DEMOS_FW" || true
		rm -rf "$BAO_DEMOS_UBOOT" || true
		rm -rf "$BAO_DEMOS_ATF" || true
	fi

	# Get firwmare
	get_rpi4_fw

	# Build uboot with the following config
	uboot_build rpi_4_defconfig

	# ARM Trusted firmware build
	atf_build
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
		;;
	esac

	# Copy files
	copy_files "$SD_DEVICE"

	print_info ">> Deployment: SUCCESS!!"

	unmount_partitions "$SD_DEVICE"
	print_info "You can now safely eject the disk..."

	print_info "================== Next steps ================== "
	print_next_steps
}

#"o\nn\np\n\n16384\n\na\nt\nc\nw\n"
#"o\nn\np\n\n16384\n\na\nt\nc\nw\n"

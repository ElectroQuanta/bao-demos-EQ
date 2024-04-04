#!/bin/bash

# Define ANSI escape codes for syntax highlighting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
ORANGE='\033[0;91m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

SD_DEVICE=""
YES_NO_OPTS=("yes" "no" "quit")


#######################################################
# @brief Echoes text with syntax highlighting.
echo_with_syntax_highlighting() {
    local color="$1"
    local text="$2"
    echo -e "${color}${text}${RESET}"
}

#######################################################
# @brief Prints info with the desired text
print_info() {
    #local text="$1"
    echo_with_syntax_highlighting "$YELLOW$BOLD" "$1"
}

#######################################################
# @brief Prints error with the desired text
print_error() {
    #local text="$1"
    echo_with_syntax_highlighting "$RED$BOLD" "$1"
}

get_user_choice() {
    local options_array=("$@")
    local num_options=${#options_array[@]}

    # Print the options to the user
    echo "Please choose an option:"
    for ((i=0; i<num_options; i++)); do
        echo "$((i+1)). ${options_array[i]}"
    done

    read -p "Enter the option number: " user_choice

    # Trim leading and trailing whitespace
    # The conditional statement checks two conditions:
    # 1. -n "$user_choice" ensures that the input is not empty.
    # 2. "$user_choice" =~ ^[0-9]+$ checks if the input contains only numeric
    # characters. This helps to ensure that the user enters a valid numeric choice.
    user_choice=${user_choice##*( )}
    user_choice=${user_choice%%*( )}

    if [[ -n "$user_choice" && "$user_choice" =~ ^[0-9]+$ ]]; then
	local index=$((user_choice - 1))
	return $index
    else
	return 255 # Invalid choice (returning a non-zero value for error)
    fi
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


sdcard_deploy() {
    ignore_error=false

    print_info ">> SD card deploy with ATF and U-Boot"

    check_requirements

    create_partition_sfdisk "$SD_DEVICE"

#    format_partition "$SD_DEVICE"
#
#    # Copy files
#    copy_files "$SD_DEVICE"
#
#    print_info ">> Deployment: SUCCESS!!"
#
#    print_info "================== Next steps ================== "
#    print_next_steps

}

sdcard_deploy

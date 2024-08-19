#!/bin/bash

# /**
#  * @file build_boot.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to build the Bao guests
#  *
#  * Requirements:
#  * 1. Bao demos repository was cloned
#  *
#  * Flow:
#  * 1. Builds Firmware for the selected target platform
#  *
#  * @copyright 2023 MIT license
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

bt="$1" # build type

# Paths
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

export BASH_MAIN=$(realpath "$script_dir/..")
echo "$BASH_MAIN"

source "$BASH_MAIN/scripts/utils.sh" || exit 1

# Setting environment
setup_env

# ============== Build Bao
print_info "======================================"
print_info "............... Building Firmware for target platform = $PLATFORM ............"
case "$PLATFORM" in
"${PLATFORMS[0]}" | "${PLATFORMS[1]}")
	echo "0 | 1"
	;;
"${PLATFORMS[2]}")
	echo "2"
	;;
"${PLATFORMS[3]}")
	echo "3"
	;;
"${PLATFORMS[4]}")
	# echo "4"
	source_helper "$BASH_MAIN/scripts/platforms/rpi4.sh"

	build_bootloader "$bt"
	;;
"${PLATFORMS[5]}")
	# echo "5"
	source_helper "$BASH_MAIN/scripts/platforms/qemu_aarch64_virt.sh"
	# qemu_build (previously done)

	# Build uboot with the following config
	uboot_build qemu_arm64_defconfig "$bt"

	# atf build
	atf_build "$bt"

	# Flash image and deploy
	qemu_deploy

	;;
"${PLATFORMS[6]}")
	echo "6"
	;;
"${PLATFORMS[7]}")
	echo "7"
	;;
"${PLATFORMS[8]}")
	echo "8"
	;;
"${PLATFORMS[9]}")
	echo "9"
	;;
"${PLATFORMS[10]}")
	echo "10"
	;;
"${PLATFORMS[11]}")
	print_info ">> BeagleBone AI build"

	source_helper "$BASH_MAIN/scripts/platforms/bb_ai_64.sh"

	ignore_error=false # dont ignore bash commands errors
	###

	build_bb_boot
	;;

"${PLATFORMS[12]}")
	print_info ">> i.MX 8MN DDR3L EVK build"

	source_helper "$BASH_MAIN/scripts/platforms/imx8mn_ddr3l_evk.sh"

	ignore_error=false # dont ignore bash commands errors

	build_boot "$bt"
	copy_files_wrkdir
	;;
esac

print_info "============ Build Successful!!!! "

cd "$BASH_MAIN" || (echo "Failed to cd into $BASH_MAIN" && exit 1)

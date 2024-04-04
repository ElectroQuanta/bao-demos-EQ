#!/bin/bash

# /**
#  * @file run.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to run the several Bao Demos
#  *
#  * Requirements:
#  * 1. A Bao Demo was previously built
#  * 2. The build environment is available at scripts/env.txt
#  *
#  * Flow:
#  * 1. Sets up running path
#  * 2. Retrieves build environment from scripts/env.txt: PLATFORM, DEMO, ARCH
#  *    BUILD_TYPE, and working directories
#  * 3. Checks the working directories:
#  *   - If missing, it will try to regenerate them
#  * 4. Checks the BUILD_TYPE:
#  *   - If auto it will run `make run` instead
#  * 5. Runs demo by fetching the appropriate script to each platform
#  *
#  * @copyright 2023 MIT license
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

# BIN_FILE (used by qemu)
ARG1="$1"

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

setup_env

# Check if Build type is auto
# setup arch according to Appendix I
case "$BUILD_TYPE" in 
    ${BUILD_TYPES[0]}) # auto
	print_info "====== Automatic Run ..."
	ignore_error=true
	make_cmd="make run"
	run_make_cmd "$make_cmd"
	print_info "======================================"
	exit
	;;
    *)
	# Other cases (manual) -> continue
	;;
esac

print_info "======================================"
print_info "Running DEMO = $DEMO for PLATFORM = $PLATFORM in $BUILD_TYPE mode"
case "$PLATFORM" in 
    ${PLATFORMS[0]} | ${PLATFORMS[1]})
	echo "0 | 1"
	;;
    ${PLATFORMS[2]})
	echo "2"
	;;
    ${PLATFORMS[3]})
	echo "3"
	;;
    ${PLATFORMS[4]})
	echo "4"
	;;
    ${PLATFORMS[5]})
	helper_script="$BASH_MAIN/scripts/platforms/qemu_aarch64_virt.sh"
	source_helper $helper_script
	# qemu_build (previously done)

	# Print info and wait for user input
	entry_addr="0x50000000"
	bin_file="$BAO_DEMOS_WRKDIR_IMGS/$ARG1"


	print_info ">> Running Qemu"
	print_info "bin_file = $bin_file"
	print_info "entry_addr = $entry_addr"

	qemu_info "$entry_addr"

	# Run
	#bin_file="$BAO_DEMOS_WRKDIR_IMGS/bao.bin"
	qemu_aarch64_virt_run "$bin_file" "$entry_addr"
	;;
    ${PLATFORMS[6]})
	echo "6"
	;;
    ${PLATFORMS[7]})
	echo "7"
	;;
    ${PLATFORMS[8]})
	echo "8"
	;;
    ${PLATFORMS[9]})
	echo "9"
	;;
    ${PLATFORMS[10]})
	echo "10"
	;;
    ${PLATFORMS[11]})
	print_info ">> Deploy BB AI-64"

	helper_script="$BASH_MAIN/scripts/platforms/bb_ai_64.sh"
	source_helper $helper_script

	sdcard_deploy
	;;
    ${PLATFORMS[12]})
	print_info ">> Deploy i.MX 8MN DDR3L EVK"

	helper_script="$BASH_MAIN/scripts/platforms/imx8mn_ddr3l_evk.sh"
	source_helper $helper_script

	sdcard_deploy
	;;
esac


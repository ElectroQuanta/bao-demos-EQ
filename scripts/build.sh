#!/bin/bash

# /**
#  * @file build.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to build the Bao guests
#  *
#  * Requirements:
#  * 1. Bao demos repository was cloned
#  *
#  * Flow:
#  * 1. Loads relevant environmental vars from env.txt
#  * 2. Builds guests for the selected DEMO
#  * 3. Builds Bao Hypervisor
#  * 4. Builds Firmware for the selected target platform
#  *
#  * @copyright 2023 MIT license
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

bt="$1"
patches="$2"

# # Set script absolute path
script_dir="$(cd "$(dirname "$0")" && pwd)"
# #echo "$script_dir"
BASH_MAIN=$(realpath "$script_dir/..")
# export BASH_MAIN
# #echo "$BASH_MAIN"
# 
# # Obtain additional utility functions
# source_helper(){
#     # local help_script=$1
#     source $(realpath "$1")
#     if [ ! $? -eq 0 ]; then
# 	print_error "Could not find helper script $1"
# 	print_error "Aborting..."
# 	exit
#     fi
#     print_info "Sourced: $1"
# }
# # source_helper "$helper_script"
source "$BASH_MAIN/scripts/utils.sh" || exit 1
# 
# # Setting environment
setup_env
#print_env

# Check if Build type is auto
# setup arch according to Appendix I
case "$BUILD_TYPE" in 
    "${BUILD_TYPES[0]}") # auto
	print_info "====== Automatic Build ..."
	make_cmd="make -j$(nproc)"
	run_make_cmd "$make_cmd"
	print_info "======================================"
	exit
	;;
    "${BUILD_TYPES[2]}") # manual step-by-step
	print_info ">> Manual step-by-step"
	echo "Run each script separately:"
	echo "- build_guests"
	echo "- build_bao"
	echo "- build_boot"
	exit
	;;
    *)
	# Other cases (manual-full) -> continue
esac


################## Build Guests ########################
source "$BASH_MAIN/scripts/build_guests.sh" "$bt" "$patches"

################# Build Bao ##########################
source "$BASH_MAIN/scripts/build_bao.sh" "$bt"

################# Build Boot ##########################
source "$BASH_MAIN/scripts/build_boot.sh" "$bt"


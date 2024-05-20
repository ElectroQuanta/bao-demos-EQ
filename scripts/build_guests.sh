#!/bin/bash

# /**
#  * @file build_guests.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to build the Bao guests
#  *
#  * Requirements:
#  * 1. Bao demos repository was cloned
#  *
#  * Flow:
#  * 1. Builds guests for the selected DEMO
#  *
#  * @copyright 2023 MIT license
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

# Set script absolute path
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

BASH_MAIN=$(realpath "$script_dir/..")
export BASH_MAIN
echo "$BASH_MAIN"

bt="$1"
patches="$2"

# Obtain additional utility functions
source_helper(){
    # local help_script=$1
    source $(realpath "$1")
    if [ ! $? -eq 0 ]; then
	print_error "Could not find helper script $1"
	print_error "Aborting..."
	exit
    fi
    print_info "Sourced: $1"
}
# source_helper "$helper_script"
source_helper "$BASH_MAIN/scripts/utils.sh"

# Setting environment
setup_env

# ============== Build guest
print_info "=================================="
print_info "............... Building guests for DEMO = $DEMO ............"
case "$DEMO" in
    "${DEMOS[0]}")
	helper_script="$BASH_MAIN/scripts/demos/baremetal/build.sh"
	source_helper "$helper_script"

	baremetal_build "$bt"
	# ---
	;;
    "${DEMOS[1]}")
	helper_script="$BASH_MAIN/scripts/demos/linux+freertos/build.sh"
	source_helper "$helper_script"

	freertos_build "$bt"
	linux_build "$bt" "$patches"
	;;
    "${DEMOS[2]}")
	helper_script="$BASH_MAIN/scripts/demos/linux+zephyr/build.sh"
	source_helper "$helper_script"

	zephyr_build "$1"
	linux_build "$1"
	;;
    "${DEMOS[3]}")
	echo "${DEMOS[3]})"
	;;
    "${DEMOS[4]}")
	helper_script="$BASH_MAIN/scripts/demos/linux/build.sh"
	source_helper "$helper_script"

	linux_build "$bt"
	;;
    "${DEMOS[5]}")
	echo "${DEMOS[5]})"
	;;
    *)
	echo "Unrecognized!!! Aborting..."
	return 1
	;;
esac

cd "$BASH_MAIN" || echo "Missing $BASH_MAIN" & return 1

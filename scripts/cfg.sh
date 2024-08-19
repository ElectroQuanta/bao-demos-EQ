#!/bin/bash

# /**
#  * @file cfg_build.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to build the several Bao Demos
#  *
#  * Requirements:
#  * 1. Bao demos repository was cloned
#  *
#  * Flow:
#  * 1. Set up the toolchain according to main README.md
#  * 2. Prompts the user to select the Demo, Platform, Build Type, and run directory
#  * 3. Selects the ARCH according to the target platform
#  * 4. Sets the working directories
#  * 5. Saves relevant environmental vars to env.txt for convenient usage by the run script
#  *
#  * @copyright 2023 MIT license
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

# PREREQUISITE: Repository was cloned
# # Clone repo and cd into it
# print_info "======================================"
# print_info "............... Bao Demos repo setup ................."
# #bao_demos_repo="$BASH_MAIN/bao-demos-mine-new"
# msg="====== Cloning Bao Demos repo..."
# cmd="git clone https://github.com/bao-project/bao-demos $repo"
# clone_repo "$repo" "$msg" "$cmd"
# cd "$repo"

save_env() {
	#	export BASH_MAIN
	#	export CROSS_COMPILE PLATFORM DEMO ARCH BUILD_TYPE
	#	export BAO_DEMOS BAO_DEMOS_WRKDIR BAO_DEMOS_WRKDIR_SRC
	#	export BAO_DEMOS_WRKDIR_BIN BAO_DEMOS_WRKDIR_PLAT BAO_DEMOS_WRKDIR_IMGS

	save_var_to_file "CROSS_COMPILE" "$CROSS_COMPILE" "$ENV_FILE"
	save_array_to_file "DEMOS" "$ENV_FILE"
	save_array_to_file "PLATFORMS" "$ENV_FILE"
	save_array_to_file "ARCHS" "$ENV_FILE"
	save_array_to_file "BUILD_TYPES" "$ENV_FILE"

	save_var_to_file "RUN_DIR" "$RUN_DIR" "$ENV_FILE"

	save_var_to_file "PLATFORM" "$PLATFORM" "$ENV_FILE"
	save_var_to_file "DEMO" "$DEMO" "$ENV_FILE"
	save_var_to_file "ARCH" "$ARCH" "$ENV_FILE"
	save_var_to_file "BUILD_TYPE" "$BUILD_TYPE" "$ENV_FILE"

	echo "BAO_DEMOS=\"$BAO_DEMOS\"" >>"$ENV_FILE"
	echo "BAO_DEMOS_WRKDIR=\"$BAO_DEMOS_WRKDIR\"" >>"$ENV_FILE"
	echo "BAO_DEMOS_WRKDIR_SRC=\"$BAO_DEMOS_WRKDIR_SRC\"" >>"$ENV_FILE"
	echo "BAO_DEMOS_WRKDIR_BIN=\"$BAO_DEMOS_WRKDIR_BIN\"" >>"$ENV_FILE"
	echo "BAO_DEMOS_WRKDIR_PLAT=\"$BAO_DEMOS_WRKDIR_PLAT\"" >>"$ENV_FILE"
	echo "BAO_DEMOS_WRKDIR_IMGS=\"$BAO_DEMOS_WRKDIR_IMGS\"" >>"$ENV_FILE"
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
BASH_MAIN=$(realpath "$script_dir/..")
echo "BASH_MAIN: $BASH_MAIN"

# Source the helper script
source "$BASH_MAIN/scripts/utils.sh" || exit 1

ignore_error=false # dont ignore bash commands errors
###

# Toolchain
print_info "======================================"
print_info ">>> Toolchain setup ................."

# fallback path in case it is not in pATH
#TOOLCHAIN_PATH=$(realpath "$BASH_MAIN/../Toolchains/arm/arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf")
TOOLCHAIN_PATH=$(realpath "$BASH_MAIN/../Toolchains/arm/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf")
TOOLCHAIN_PREFIX=aarch64-none-elf-
#TOOLCHAIN_PATH=$(realpath "/home/zmp/Documents/br-main/toolchains/aarch64-buildroot-linux-gnu_sdk-buildroot")
#TOOLCHAIN_PREFIX=aarch64-linux-
CROSS_COMPILE="$TOOLCHAIN_PREFIX"
echo "$TOOLCHAIN_PATH"
# Check if CROSS_COMPILE is in path
cross_compile_gcc="${CROSS_COMPILE}gcc"

# Run the command and capture its exit status
if ! $cross_compile_gcc --version >/dev/null 2>&1; then
    echo "Error: Cross-compile GCC command failed."
    echo "Setting fallback toolchain..."
    CROSS_COMPILE="$TOOLCHAIN_PATH"/bin/"$TOOLCHAIN_PREFIX"
    cross_compile_gcc="${CROSS_COMPILE}gcc"
    # Test cross compilation toolchain without echoing its output to the terminal
    $cross_compile_gcc --version >/dev/null 2>&1 # if errors, it exits
fi
print_info "CROSS_COMPILE = $CROSS_COMPILE"
print_info "======================================"

# Setup PLATFORM and DEMO according to Appendix I
ignore_error=true # error handling is done in place
DEMOS=("baremetal" "linux+freertos" "linux+zephyr" "zephyr+baremetal" "linux" "linux+baremetal")
PLATFORMS=("zcu102" "zcu104" "imx8qm" "tx2" "rpi4" "qemu-aarch64-virt" "fvp-a-aarch64" "fvp-a-aarch32" "fvp-r-aarch64" "fvp-r-aarch32" "qemu-riscv64-virt" "bb-ai-64" "imx8mn-ddr3l-evk")
ARCHS=("aarch64" "aarch32" "riscv64")
BUILD_TYPES=("auto" "manual-full" "manual-step")
YES_NO_OPTS=("yes" "no" "quit")

# Request user input for demo
print_info "========== Select Demo =========="
get_user_choice "${DEMOS[@]}"
demo_index=$?
if [ $demo_index -eq 255 ]; then
    print_error "Invalid choice. Exiting."
    exit 1
fi
print_info "======================================"
echo ""

print_info "========== Select Platform =========="
# Request user input for platform
get_user_choice "${PLATFORMS[@]}"
plat_index=$?
if [ $plat_index -eq 255 ]; then
    print_error "Invalid choice. Exiting."
    exit 1
fi
print_info "======================================"
echo ""

print_info "========== Select Build Type =========="
# Request user input for platform
get_user_choice "${BUILD_TYPES[@]}"
build_type_index=$?
if [ $build_type_index -eq 255 ]; then
    print_error "Invalid choice. Exiting."
    exit 1
fi
print_info "======================================"
echo ""

ignore_error=false
# Platform, Demo, and Arch
PLATFORM=${PLATFORMS[$plat_index]}           # qemu-aarch64-virt
DEMO=${DEMOS[$demo_index]}                   # linux + freertos
BUILD_TYPE=${BUILD_TYPES[$build_type_index]} # Build Type

# setup arch according to Appendix I
case "$PLATFORM" in
"${PLATFORMS[10]}")
	ARCH=${ARCHS[2]} # riscv64
	;;
"${PLATFORMS[8]}" | "${PLATFORMS[9]}")
	ARCH=${ARCHS[1]} # aarch32
	;;
*)
	# Other cases (aarch64)
	ARCH=${ARCHS[0]} # aarch64
	;;
esac

# Saving variables for run script
ENV_FILE="$BASH_MAIN/scripts/env.txt"
rm "$ENV_FILE" || true # remove file before each run

# Saving variables for run script
RUN_DIR="$BASH_MAIN"

# Working directories
BAO_DEMOS="$BASH_MAIN"
BAO_DEMOS_WRKDIR=$BAO_DEMOS/wrkdir
BAO_DEMOS_WRKDIR_SRC=$BAO_DEMOS_WRKDIR/srcs
BAO_DEMOS_WRKDIR_BIN=$BAO_DEMOS_WRKDIR/bin
BAO_DEMOS_WRKDIR_PLAT=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM
BAO_DEMOS_WRKDIR_IMGS=$BAO_DEMOS_WRKDIR_PLAT/$DEMO

# Prompt user to remove previous build
ignore_error=true
print_info "Remove previous build?"
get_user_choice "${YES_NO_OPTS[@]}"
answer_index=$?
if [ $answer_index -eq 0 ]; then # yes
	if [ -d "$BAO_DEMOS_WRKDIR" ]; then
		print_info ">> Removing previous working directory"
		rm -rf "$BAO_DEMOS_WRKDIR" || true
	fi
fi

create_dir "$BAO_DEMOS_WRKDIR"
create_dir "$BAO_DEMOS_WRKDIR_SRC"
create_dir "$BAO_DEMOS_WRKDIR_BIN"
create_dir "$BAO_DEMOS_WRKDIR_IMGS"

# Save environment and print it
save_env
print_env

print_info "Call build.sh for building..."

#!/bin/bash

# Set script absolute path
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

export BASH_MAIN="$script_dir/.."
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

# Retrieve saved variables
ENV_FILE="$BASH_MAIN/scripts/env.txt"
source_helper "$ENV_FILE"

# Platform, Demo, and Arch (setup by build script according to Appendix I)
print_info "======================================"
print_info "............... Environment info ................."
print_info "PLATFORM: $PLATFORM"
print_info "DEMO: $DEMO"
print_info "ARCH: $ARCH"
print_info "BUILD_TYPE: $BUILD_TYPE"
print_info "======================================"

# changing to run directory
ignore_error=false
RUN_DIR="$BASH_MAIN"
cd "$RUN_DIR"

ignore_error=true

# check var is empty
[ -z "$PLATFORM" ] && echo "$PLATFORM: empty... Aborting" && exit
[ -z "$DEMO" ] && echo "$DEMO: empty... Aborting" && exit
[ -z "$ARCH" ] && echo "$ARCH: empty... Aborting" && exit

export PLATFORM="$PLATFORM"
export DEMO="$DEMO"
export ARCH="$ARCH"

# Working directories (setup by build script)
#if [ -z "$BAO_DEMOS" ]  ; then
print_info ">> Regenerating directories"
export BAO_DEMOS=$(realpath .)

export BAO_DEMOS_WRKDIR=$BAO_DEMOS/wrkdir
export BAO_DEMOS_WRKDIR_SRC=$BAO_DEMOS_WRKDIR/srcs
export BAO_DEMOS_WRKDIR_BIN=$BAO_DEMOS_WRKDIR/bin
export BAO_DEMOS_WRKDIR_PLAT=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM
export BAO_DEMOS_WRKDIR_IMGS=$BAO_DEMOS_WRKDIR_PLAT/$DEMO
#fi

print_info "======================================"
print_info "............... Setting up Working directories ................."
print_info "BAO_DEMOS             = $BAO_DEMOS"
print_info "BAO_DEMOS_WRKDIR      = $BAO_DEMOS_WRKDIR"
print_info "BAO_DEMOS_WRKDIR_SRC  = $BAO_DEMOS_WRKDIR_SRC"
print_info "BAO_DEMOS_WRKDIR_BIN  = $BAO_DEMOS_WRKDIR_BIN"
print_info "BAO_DEMOS_WRKDIR_PLAT = $BAO_DEMOS_WRKDIR_PLAT"
print_info "BAO_DEMOS_WRKDIR_IMGS = $BAO_DEMOS_WRKDIR_IMGS"
print_info "======================================"

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
	helper_script="$BASH_MAIN/scripts/platforms/rpi4.sh"
	source_helper $helper_script
	# qemu_build (previously done)

	# Deploy to the SD card
	sdcard_deploy
	echo "$?"
	;;
    ${PLATFORMS[5]})
	print_error "QEMU platform is not deployable using SD card..."
	print_error "Abort..."
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
esac

#!/bin/bash

# setting initial constraints
# src: https://github.com/bao-project/bao-demos/blob/master/demos/linux+freertos/README.md
case $PLATFORM in
    fvp-a-aarch64 | fvp-a-aarch32 | fvp-r-aarch64 | fvp-r-aarch32)
	# If you are targetting an MPU platform (i.e. fvp-r), set:
	export FVPR_VM_IMAGES="$BAO_DEMOS_WRKDIR_IMGS/freertos.bin@0x10000000 \
    	$BAO_DEMOS_WRKDIR_IMGS/linux.bin@0x20000000"
	export FREERTOS_PARAMS="MEM_BASE=0x10000000"
	;;
    *)
	export FREERTOS_PARAMS="STD_ADDR_SPACE=y"
	;;
esac


# loading helper script to build freertos
helper_script="$BASH_MAIN/scripts/guests/freertos/build.sh"
source_helper $helper_script

# loading helper script to build Linux guest
helper_script="$BASH_MAIN/scripts/guests/linux/build.sh"
source_helper $helper_script

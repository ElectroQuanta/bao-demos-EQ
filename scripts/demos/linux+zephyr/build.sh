#!/bin/bash

# setting initial constraints
# src: https://github.com/bao-project/bao-demos/blob/master/demos/linux+freertos/README.md
case $PLATFORM in
    fvp-a-aarch64 | fvp-a-aarch32 | fvp-r-aarch64 | fvp-r-aarch32)
	# If you are targetting an MPU platform (i.e. fvp-r), set:
	export FVPR_VM_IMAGES="$BAO_DEMOS_WRKDIR_IMGS/zephyr.bin@0x24000000 \
    $BAO_DEMOS_WRKDIR_IMGS/linux.bin@0x28000000"
	;;
    *)
	;;
esac

# loading helper script to build freertos
helper_script="$BASH_MAIN/scripts/guests/zephyr/build.sh"
source_helper $helper_script

# loading helper script to build Linux guest
helper_script="$BASH_MAIN/scripts/guests/linux/build.sh"
source_helper $helper_script

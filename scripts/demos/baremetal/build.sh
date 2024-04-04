#!/bin/bash

# setting initial constraints
# src: https://github.com/bao-project/bao-demos/blob/master/demos/baremetal/README.md
case $PLATFORM in
    fvp-a-aarch64 | fvp-a-aarch32 | fvp-r-aarch64 | fvp-r-aarch32)
	# If you are targetting an MPU platform (i.e. fvp-r), set:
	export FVPR_VM_IMAGES="$BAO_DEMOS_WRKDIR_IMGS/baremetal.bin@0x10000000"
	export BAREMETAL_PARAMS="MEM_BASE=0x10000000"
	;;
    *)
	;;
esac

# loading helper script to build baremetal app
helper_script="$BASH_MAIN/scripts/guests/baremetal/build.sh"
source_helper $helper_script "$1"

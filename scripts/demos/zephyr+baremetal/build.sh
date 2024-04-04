#!/bin/bash

# Zephyr+Baremetal Demo
# src: https://raw.githubusercontent.com/bao-project/bao-demos/master/demos/zephyr%2Bbaremetal/README.md

# Configure the baremetal app for communication:
export BAREMETAL_PARAMS="DEMO_IPC=y"

# setting initial constraints
# src: https://github.com/bao-project/bao-demos/blob/master/demos/linux+freertos/README.md
case $PLATFORM in
    fvp-a-aarch64 | fvp-a-aarch32 | fvp-r-aarch64 | fvp-r-aarch32)
	# If you are targetting an MPU platform (i.e. fvp-r), set:
	export FVPR_VM_IMAGES="$BAO_DEMOS_WRKDIR_IMGS/zephyr.bin@0x24000000 \
    $BAO_DEMOS_WRKDIR_IMGS/baremetal.bin@0x10000000"
	# To build the baremetal app, in case you are targeting an MPU platform (e.g.
	# fvp-r), set:
	export BAREMETAL_PARAMS="$BAREMETAL_PARAMS MEM_BASE=0x10000000"
	;;
    *)
	;;
esac

# loading helper script to build zephyr guest
helper_script="$BASH_MAIN/scripts/guests/zephyr/build.sh"
source_helper $helper_script

# loading helper script to build baremetal guest
helper_script="$BASH_MAIN/scripts/guests/baremetal/build.sh"
source_helper $helper_script

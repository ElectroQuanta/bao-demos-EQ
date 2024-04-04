#!/bin/bash

freertos_build(){
#    local plat=$1
#    PLATFORMS=("zcu102" "zcu104" "imx8qm" "tx2" "rpi4" "qemu-aarch64-virt" "fvp-a-aarch64" "fvp-a-aarch32" "fvp-r-aarch64" "fvp-r-aarch32" "qemu-riscv64-virt")

    print_info "=========================================="
    print_info "..................... FreeRTOS ....................."
    # src: https://github.com/bao-project/bao-demos/blob/master/guests/freertos/README.md
    # Setup an environment variable for the FreeRTOS repo:
    export BAO_DEMOS_FREERTOS=$BAO_DEMOS_WRKDIR_SRC/freertos
    # Cloning repo
    ignore_error=true
    repo="$BAO_DEMOS_FREERTOS"
    msg="====== Cloning Bao FreeRTOS: branch demo"
    cmd="git clone --recursive --shallow-submodules\
	https://github.com/bao-project/freertos-over-bao.git\
	$repo --branch demo"
    clone_repo "$repo" "$msg" "$cmd"

    # Building
    print_info "======  Build"
    make_cmd="make -C $BAO_DEMOS_FREERTOS PLATFORM=$PLATFORM $FREERTOS_PARAMS"
    run_make_cmd "$make_cmd"

    # Copying img
    print_info "======  Copying the FreeRTOS image to the final guest image dir"
    ignore_error=false
    cp -v $BAO_DEMOS_FREERTOS/build/$PLATFORM/freertos.bin $BAO_DEMOS_WRKDIR_IMGS
    print_info "======================================"
}


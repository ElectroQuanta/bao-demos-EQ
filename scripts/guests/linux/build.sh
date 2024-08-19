#!/bin/bash

setup_linux_kernel(){
    local bt="$1"
    local patches="$2"
    
    ############### Download Linux kernel source ########################
    # Setup linux environment variables
    export BAO_DEMOS_LINUX=$BAO_DEMOS/guests/linux

    #Setup repo and version.
    case $PLATFORM in
	imx8qm | imx8mn-ddr3l-evk )
	    # Specifically for the NXP iMX platforms use:
	    export BAO_DEMOS_LINUX_REPO=https://github.com/nxp-imx/linux-imx
	    #export BAO_DEMOS_LINUX_VERSION=rel_imx_5.4.24_2.1.0
	    #export BAO_DEMOS_LINUX_VERSION=rel_imx_5.4.70_2.3.7
	    #export BAO_DEMOS_LINUX_VERSION=lf-5.10.y
	    #export BAO_DEMOS_LINUX_VERSION=lf-6.6.3-1.0.0
	    export BAO_DEMOS_LINUX_VERSION=lf-6.1.55-2.2.0
	    #export BAO_DEMOS_LINUX_VERSION=v5.17
	    ;;
	*)
	    # For all other platforms clone the latest mainline Linux release:
	    export BAO_DEMOS_LINUX_REPO=https://github.com/torvalds/linux.git
	    export BAO_DEMOS_LINUX_VERSION=v6.1
	    ;;
    esac

    # Setup an environment variable pointing to Linux's source code:
    export BAO_DEMOS_LINUX_SRC=$BAO_DEMOS_WRKDIR_SRC/linux-$BAO_DEMOS_LINUX_VERSION

    # And make a shallow clone of the target repo:
    # Cloning repo
    ignore_error=false
    if [ "$bt" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_LINUX_SRC" || true
    fi

    if [ ! -d "$BAO_DEMOS_LINUX_SRC" ]; then
	print_info "Cloning $BAO_DEMOS_LINUX_VERSION into $BAO_DEMOS_LINUX_SRC: branch $branch"
	git clone $BAO_DEMOS_LINUX_REPO "$BAO_DEMOS_LINUX_SRC" --depth 1\
	    --branch $BAO_DEMOS_LINUX_VERSION
    fi
    
    # Apply patches
    if [ "$patches" == "1" ] ; then
	print_info ">> Applying kernel patches..."
	cd "$BAO_DEMOS_LINUX_SRC" || (echo "Missing $BAO_DEMOS_LINUX_SRC" && exit 1)
	git apply "$BAO_DEMOS_LINUX/patches/$BAO_DEMOS_LINUX_VERSION/*.patch"
    fi

    # Finally, setup and environment variable pointing to the target architecture and 
    # platform specific config to be used by buildroot:
    BAO_DEMOS_LINUX_CFG_FRAG=$(ls "$BAO_DEMOS_LINUX/configs/base.config"\
					 "$BAO_DEMOS_LINUX/configs/$ARCH.config"\
					 "$BAO_DEMOS_LINUX/configs/$PLATFORM.config" 2> /dev/null)
    export BAO_DEMOS_LINUX_CFG_FRAG
}

buildroot_build(){
    ###### Use Buildroot to build Linux with a built-in initramfs ##############
    local bt="$1"

    # Setup buildroot environment variables:
    export BAO_DEMOS_BUILDROOT="$BAO_DEMOS_WRKDIR_SRC/\
buildroot-$ARCH-$BAO_DEMOS_LINUX_VERSION"
    export BAO_DEMOS_BUILDROOT_DEFCFG=$BAO_DEMOS_LINUX/buildroot/$ARCH.config
    export LINUX_OVERRIDE_SRCDIR=$BAO_DEMOS_LINUX_SRC


    if [ "$bt" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_BUILDROOT" || true
    fi

    if [ ! -d "$BAO_DEMOS_BUILDROOT" ]; then
	repo="https://github.com/buildroot/buildroot.git"
	#branch="2022.11"
	#branch="2023.11.1"
	branch="2024.02.3"
	print_info "Cloning $repo into $BAO_DEMOS_BUILDROOT: branch $branch"
	git clone $repo $BAO_DEMOS_BUILDROOT --depth 1\
	    --branch $branch
    fi
    cd "$BAO_DEMOS_BUILDROOT" || ( echo "Missing $BAO_DEMOS_BUILDROOT" && return 1 )


    if [ "$bt" == "clean" ] ; then
	echo "cleaning previous build..."
	make distclean
    fi

    if [ "$bt" == "clean" ] || [ "$bt" == "deep" ] ; then
	# Use our provided buildroot defconfig, which itselfs points to the a Linux 
	# kernel defconfig and patches (mainly for the inter-vm communication drivers)
	# and build:
	ignore_error=false
	print_info "====== Build Buildroot"
	make defconfig BR2_DEFCONFIG="$BAO_DEMOS_BUILDROOT_DEFCFG"
	print_info "$BAO_DEMOS_BUILDROOT_DEFCFG"
	read -rp "Press to build buildroot: " user_input
	# Building
	ignore_error=true
	make_cmd="make linux-reconfigure all"
	run_make_cmd "$make_cmd"

	ignore_error=false
	mv "$BAO_DEMOS_BUILDROOT/output/images/Image"\
	   "$BAO_DEMOS_BUILDROOT/output/images/Image-$PLATFORM"
    fi
}

wrap_kernel_dtb(){
    #################################################################
    ## Build the device tree and wrap it with the kernel image
    # ---
    # **NOTE**
    # If your target demo features multiple Linux virtual machines, you will have to 
    # repeat this last step for each of these, which should correspond to 
    # different *.dts* files in *$BAO_DEMOS/$DEMO/devicetrees*.
    # ---
    # 
    # The device tree(s) for your target demo are available in 
    # *$BAO_DEMOS/$DEMO/devicetrees/$PLATFORM*. For a device tree file named 
    # *linux.dts* define a virtual machine variable:
    export BAO_DEMO_LINUX_VM=linux

    make -C "$BAO_DEMOS_LINUX/lloader clean" || true

    # Then build:
    ignore_error=false
    print_info "======== Building device tree"
    dtc "$BAO_DEMOS/demos/$DEMO/devicetrees/$PLATFORM/$BAO_DEMO_LINUX_VM.dts" >\
	"$BAO_DEMOS_WRKDIR_IMGS/$BAO_DEMO_LINUX_VM.dtb"

    # Wrap the kernel image and device tree blob in a single binary:
    print_info "======== Wrap kernel image and device tree blob into a single binary"

    # Building
    ignore_error=true
    make_cmd="make -C $BAO_DEMOS_LINUX/lloader\
	 ARCH=$ARCH\
	 IMAGE=$BAO_DEMOS_BUILDROOT/output/images/Image-$PLATFORM\
	 DTB=$BAO_DEMOS_WRKDIR_IMGS/$BAO_DEMO_LINUX_VM.dtb\
	 TARGET=$BAO_DEMOS_WRKDIR_IMGS/$BAO_DEMO_LINUX_VM"
    run_make_cmd "$make_cmd"

}

linux_build() {
    #    local plat=$1
    #    PLATFORMS=("zcu102" "zcu104" "imx8qm" "tx2" "rpi4" "qemu-aarch64-virt" "fvp-a-aarch64" "fvp-a-aarch32" "fvp-r-aarch64" "fvp-r-aarch32" "qemu-riscv64-virt")
    local bt=$1
    local patch=$2
    
    print_info "========================================"
    print_info ".................... Building linux ................ "
    print_info "Requirements: cpio, unzip, dtc"

    # setup linux kernel build_type{deep, clean, nil} patches{1,0}
    setup_linux_kernel "$bt" "$patch"
    #setup_linux_kernel deep 0

    # Build linux system (kernel + filesystem) with buildroot build_type{deep, clean, nil}
    buildroot_build "$bt"
    #buildroot_build deep

    # wrap linux and device tree into a single blob
    wrap_kernel_dtb

    # ---
    # **NOTE**
    # The password for `root` is `root`.
    # ---
    print_info "========================================"
    
}


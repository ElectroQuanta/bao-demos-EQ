#!/bin/bash


DEBUG_ATF=0

qemu_build() {
    print_info "====== Qemu_build"
    # src: https://github.com/bao-project/bao-demos/blob/master/platforms/qemu-aarch64-virt/README.md
    export BAO_DEMOS_QEMU=$BAO_DEMOS_WRKDIR_SRC/qemu-$ARCH
    git clone https://github.com/qemu/qemu.git $BAO_DEMOS_QEMU --depth 1\
	--branch v7.2.0
    cd $BAO_DEMOS_QEMU
    ./configure --target-list=aarch64-softmmu --enable-slirp
    make -j$(nproc)
    sudo make install
}

qemu_build_new(){
    # Please use this more recent version, if you want to build qemu
    # src: https://www.qemu.org/download/
    QEMU_VER=8.2.1
    wget https://download.qemu.org/qemu-$QEMU_VER.tar.xz
    tar xvJf qemu-$QEMU_VER.tar.xz
    cd qemu-$QEMU_VER
    ./configure --target-list=aarch64-softmmu --enable-slirp
    make -j$(nproc)
    sudo make install
    # Qemu should now be available system-wide
}

uboot_build() {
    # retrieve cfg
    #local cfg=$1
    
    export BAO_DEMOS_UBOOT=$BAO_DEMOS_WRKDIR_SRC/u-boot

    print_info "========================== "
    print_info "...................... Building U-Boot ................... "
    # Cloning repo
    ignore_error=true
    repo_dir="$BAO_DEMOS_UBOOT"
    branch="v2022.10"

    # Cloning repo
    if [ "$1" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_UBOOT" || true
    fi

    if [ ! -d "$BAO_DEMOS_UBOOT" ]; then
	echo "Rebuilding...."
	msg="====== Cloning UBOOT: branch $branch"
	cmd="git clone https://github.com/u-boot/u-boot.git $repo_dir --depth 1\
	    --branch $branch"
	
	clone_repo "$repo_dir" "$msg" "$cmd"
    fi

    # Clean the build
    make -C "$BAO_DEMOS_UBOOT" clean || true

    ignore_error=false
    cd $BAO_DEMOS_UBOOT
    print_info "========================== "
    print_info ">> Generating config: $1"
    make "$1"
    echo "CONFIG_SYS_TEXT_BASE=0x60000000" >> "$BAO_DEMOS_UBOOT/.config"
    echo "CONFIG_TFABOOT=y" >> "$BAO_DEMOS_UBOOT/.config"

    # Building
    ignore_error=true
    make_cmd="make -j$(nproc)"
    run_make_cmd "$make_cmd"

    # Copying bin to image dir
    print_info "====== Copying the U-Boot binary into the final image directory"
    ignore_error=false
    cp -v $BAO_DEMOS_UBOOT/u-boot.bin $BAO_DEMOS_WRKDIR/imgs/$PLATFORM
    print_info "======================================"
}

atf_build() {
    export BAO_DEMOS_ATF="${BAO_DEMOS_WRKDIR_SRC}/arm-trusted-firmware-${ARCH}"

    print_info "=================================================="
    print_info "...................... Building ATF ................... "

    # Cloning repo
    ignore_error=true
    repo_dir="$BAO_DEMOS_ATF"

    # Cloning repo
    if [ "$1" == "deep" ] ; then
	echo "Removing previous build..."
	rm -rf "$BAO_DEMOS_ATF" || true
    fi


    if [ ! -d "$BAO_DEMOS_ATF" ]; then
	echo "Rebuilding...."
	msg="====== Cloning ATF: branch demo"
	cmd="git clone https://github.com/bao-project/arm-trusted-firmware.git\
	    $BAO_DEMOS_ATF --branch bao/demo --depth 1"
	clone_repo "$repo_dir" "$msg" "$cmd"
	
    fi

    cd "$repo_dir"

    # Clean the build
    make -C "$BAO_DEMOS_ATF" distclean || true

    log_lvl=50
    print_info ">> Building..."
    #make_cmd="make -C $BAO_DEMOS_ATF -j$(nproc) bl31 PLAT=imx8mn DEBUG=$DEBUG_ATF CFLAGS=-Os LOG_LEVEL=$log_lvl"

    ignore_error=false
    print_info "====== Qemu Build with ATF and U-Boot "
    make PLAT=qemu bl1 -j$(nproc) DEBUG=$DEBUG_ATF CFLAGS=-Os LOG_LEVEL=$log_lvl\
	 fip BL33=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM/u-boot.bin\
	 QEMU_USE_GIC_DRIVER=QEMU_GICV3
}

qemu_deploy() {
    print_info "====== Flash Image"
    print_info "======== Merging 1st stage bootloader into image"
    dd if=$BAO_DEMOS_ATF/build/qemu/release/bl1.bin\
       of=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM/flash.bin
    print_info "======== Merging Firmware image package into image"
    dd if=$BAO_DEMOS_ATF/build/qemu/release/fip.bin\
       of=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM/flash.bin seek=64 bs=4096 conv=notrunc
    print_info "=================================================="
}

#============ Build Firmware and Deploy
qemu_aarch64_virt_run(){
    local bin_file="$1"
    local entry_addr="$2"

    print_info ">> Loading QEMU with binary $bin_file @ $entry_addr"

    ignore_error=false
    qemu-system-aarch64 \
	-nographic\
	-M virt,secure=on,virtualization=on,gic-version=3 \
	-cpu cortex-a53 -smp 4 -m 4G\
	-bios $BAO_DEMOS_WRKDIR/imgs/$PLATFORM/flash.bin \
	-device loader,file=$bin_file,addr=$entry_addr,force-raw=on\
	-device virtio-net-device,netdev=net0\
	-netdev user,id=net0,net=192.168.42.0/24,hostfwd=tcp:127.0.0.1:5555-:22\
	-device virtio-serial-device -chardev pty,id=serial3 -device virtconsole,chardev=serial3
}

qemu_info() {
    print_info "---------------------------------------------------------------------"
    print_info "5) Setup connections and jump to Bao"

    echo ""
    echo " --------------------------------------------------------------------------------
Qemu will let you know in which pseudo-terminals it placed the virtio serial.
For example:

    char device redirected to /dev/pts/4 (label serial3)

If you are running more than one guest, open a new terminal and connect to it.
For example:

    screen /dev/pts/4

If you are running a Linux guest you can also connect via ssh to it by opening
a new terminal and running:

    ssh root@localhost -p 5555

Finally, make u-boot jump to where the bao image was loaded:

    go $1

When you want to leave QEMU press Ctrl-a then x.
"
    read -p "Press any key to continue... " user_choice
}

#!/bin/bash

baremetal_build() {
    # --- Single baremetal
    # Get the directory containing the script
    script_dir=$(dirname "$(realpath "$0")")
    
    export BAO_DEMOS_BAREMETAL=$BAO_DEMOS_WRKDIR_SRC/baremetal
    clone_dir="$BAO_DEMOS_BAREMETAL"
    #repo=https://github.com/ElectroQuanta/bao-baremetal-guest-porting.git
    repo=git@github.com:ElectroQuanta/bao-baremetal-guest-porting.git
    #branch=demo
    branch=master
    msg="====== Cloning Bao Baremetal Guest repo..."
    #cmd="git clone https://github.com/bao-project/bao-baremetal-guest.git\
	#	    --branch demo $repo"

    # Cloning repo
    if [ "$1" == "deep" ] ; then
	rm -rf "$BAO_DEMOS_BAREMETAL" || true
    fi

    if [ ! -d "$BAO_DEMOS_BAREMETAL" ]; then
	echo "Rebuilding...."
	cmd="git clone $repo --branch $branch $clone_dir"
	clone_repo "$clone_dir" "$msg" "$cmd"
    fi

    # Clean the build
    make -C "$clone_dir" clean || true

    # Building
    print_info "====== Building ..."
    cd $clone_dir # change directory before generating compile_commands
    make_cmd="compiledb make -C $clone_dir PLATFORM=$PLATFORM $BAREMETAL_PARAMS 2>&1"
    ignore_error=true
    run_make_cmd "$make_cmd"

    # Copying img
    print_info "====== Copying binary to final image's directory..."
    ignore_error=false
    cp -v $BAO_DEMOS_BAREMETAL/build/$PLATFORM/baremetal.bin \
       $BAO_DEMOS_WRKDIR_IMGS

    cd $script_dir
}

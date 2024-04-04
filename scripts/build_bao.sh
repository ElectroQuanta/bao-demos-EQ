#!/bin/bash

# /**
#  * @file build_bao.sh
#  * @author Jose Pires
#  * @date 2023-08-09
#  *
#  * @brief Bootstrap script used to build the Bao guests
#  *
#  * Requirements:
#  * 1. Bao demos repository was cloned
#  *
#  * Flow:
#  * 1. Builds Bao Hypervisor
#  *
#  * @copyright 2023 MIT license
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */


bt="$1" # build type
patch="$2" # patches

# Set script absolute path
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "$script_dir"

export BASH_MAIN=$(realpath "$script_dir/..")
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

# Setting environment
setup_env

# ============== Build Bao
print_info "======================================"
print_info "...................... Building Bao .........................."
export BAO_DEMOS_BAO=$BAO_DEMOS_WRKDIR_SRC/bao
clone_dir="$BAO_DEMOS_BAO"
#branch="demo"
branch="main"
msg="====== Cloning Bao hypervisor repo: branch $branch..."
# cmd="git clone https://github.com/bao-project/bao-hypervisor $repo\
# 	--branch $branch"


# Cloning repo
if [ "$bt" == "deep" ] ; then
    echo "Removing previous build..."
    rm -rf "$BAO_DEMOS_BAO" || true
fi

if [ ! -d "$BAO_DEMOS_BAO" ]; then
    echo "Rebuilding...."
    cmd="git clone git@github.com:ElectroQuanta/bao-hypervisor-porting.git $clone_dir\
	--branch $branch"
    clone_repo "$clone_dir" "$msg" "$cmd"
fi

cd "$clone_dir"

# Update submodules
git submodule init
git submodule update --recursive

# Clean the build
make -C "$clone_dir" clean || true

print_info "====== Copying the config..."
[ ! -d $BAO_DEMOS_WRKDIR_IMGS/config ] && mkdir -p $BAO_DEMOS_WRKDIR_IMGS/config
ignore_error=false
cp -vL $BAO_DEMOS/demos/$DEMO/configs/$PLATFORM.c\
   $BAO_DEMOS_WRKDIR_IMGS/config/$DEMO.c

# Patch console.c (main branch): temporary fix
# if [ "$branch" == "main" ]; then
#     ######################### Patch
#     patch_file "$BAO_DEMOS_BAO/src/core/console.c" 20 "void uart_putc(volatile bao_uart_t *, const char );\n"
#     ############################################################
# fi

print_info "====== Build..."
ignore_error=true
make_cmd="compiledb make -C $BAO_DEMOS_BAO \
PLATFORM=$PLATFORM \
CONFIG_REPO=$BAO_DEMOS_WRKDIR_IMGS/config \
CONFIG=$DEMO \
CPPFLAGS=-DBAO_DEMOS_WRKDIR_IMGS=$BAO_DEMOS_WRKDIR_IMGS"

if [ "$patch" -eq 1 ]; then
    pat=" CFLAGS+=-DPLATFORM_IMX8MN_DDR3L_EVK"
   print_info ">> Patching: $pat"
   make_cmd+="$pat"
fi

run_make_cmd "$make_cmd"

print_info "====== Copying the resulting binary into the final image directory"
ignore_error=false
cp -v $BAO_DEMOS_BAO/bin/$PLATFORM/$DEMO/bao.bin\
   $BAO_DEMOS_WRKDIR_IMGS
print_info "======================================"

cd "$BASH_MAIN"

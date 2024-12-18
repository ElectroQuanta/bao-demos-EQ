#!/bin/bash

# Copy the packages into buildroot
pkgs=("libcamera-rpi" "rpicam-apps")
for pkg in "${pkgs[@]}"; do
    if [ ! -d "${pkg}" ]; then
        cp -r "${pkg}" wrkdir/srcs/buildroot/
    fi
done

# Add the config into buildroot (only if it does not exist)
grep -q 'source "package/libcamera-rpi/Config.in"' package/Config.in || \
sed -i '/menu "Multimedia"/a \
\ \ source "package/libcamera-rpi/Config.in"\n\
\ \ source "package/rpicam-apps/Config.in"' package/Config.in

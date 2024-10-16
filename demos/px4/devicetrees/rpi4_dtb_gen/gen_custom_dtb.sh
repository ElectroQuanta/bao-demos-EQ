#!/bin/bash

# We need to apply the following:
## dtoverlay=disable-bt
## dtoverlay=uart5
## enable_uart=1
## uart_2ndstage=1
### Enable SPI and I2C
## dtoverlay=sc16is752-spi1
## dtparam=i2c_arm=on,i2c_arm_baudrate=400000
## dtparam=spi=on
## dtparam=i2c_vc=on
### Other configurations
##camera_auto_detect=1
##dtoverlay=vc4-kms-v3d,cma-512
##auto_initramfs=1

# We're gonna use dtmerge
# Usage:
#    dtmerge [<options] <base dtb> <merged dtb> - [param=value] ...
#        to apply a parameter to the base dtb (like dtparam)
#    dtmerge [<options] <base dtb> <merged dtb> <overlay dtb> [param=value] ...
#        to apply an overlay with parameters (like dtoverlay)
#  where <options> is any of:
#    -d      Enable debug output


orig_dtb=bcm2711-rpi-4-b.dtb
merged_dtb=linux.dtb

# overlays
ov=overlays
ov_disable_bt="${ov}/disable-bt.dtbo"
ov_uart5="${ov}/uart5.dtbo"

# Always backup
cp -v "${orig_dtb}" "${merged_dtb}"

# Disable bt
printf "\n>> Disabling Bluetooth\n"
dtmerge -d "${merged_dtb}" "${merged_dtb}" "${ov_disable_bt}"
# Enable UART 5
printf "\n>> Enabling UART 5\n"
dtmerge -d "${merged_dtb}" "${merged_dtb}" "${ov_uart5}"

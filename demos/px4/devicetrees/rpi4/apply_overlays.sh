#!/bin/bash 

# Apply the overlays to obtain the correct dtb
orig_dtb=bcm2711-rpi-4-b.dtb
merged_dtb=merged.dtb
merged_dts=merged.dts

# create a backup
cp -v ${orig_dtb} ${merged_dtb}

# Apply all overlays
# disable bluetooth
# enable uart5 and uart0
# enable spi and i2c
# enable vc4-kms-v3d for video
# Usage:
#     dtmerge [<options] <base dtb> <merged dtb> - [param=value] ...
#         to apply a parameter to the base dtb (like dtparam)
#     dtmerge [<options] <base dtb> <merged dtb> <overlay dtb> [param=value] ...
#         to apply an overlay with parameters (like dtoverlay)
#   where <options> is any of:
#     -d      Enable debug output
#     -h      Show this help message
echo ">> Applying overlays and parameters"
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/disable-bt.dtbo
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/uart5.dtbo
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/uart0.dtbo
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/sc16is752-spi1.dtbo 
dtmerge -d ${merged_dtb} ${merged_dtb} - i2c_arm=on
dtmerge -d ${merged_dtb} ${merged_dtb} - i2c_arm_baudrate=400000
dtmerge -d ${merged_dtb} ${merged_dtb} - spi=on
dtmerge -d ${merged_dtb} ${merged_dtb} - i2c_vc=on
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/vc4-kms-v3d.dtbo cma=512
dtmerge -d ${merged_dtb} ${merged_dtb} overlays/imx708.dtbo 

echo ">> Generating dts"
dtc -@ ${merged_dtb} > ${merged_dts}

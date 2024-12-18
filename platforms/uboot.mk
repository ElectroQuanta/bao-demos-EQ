# Include common function
include $(bao_demos)/common.mk

uboot_repo:=https://github.com/u-boot/u-boot.git
uboot_version:=v2024.07
uboot_src:=$(wrkdir_src)/u-boot

uboot_load_bin:=linux.bin
uboot_load_bin_addr:=0x20000000
env_file:=$(uboot_src)/board/raspberrypi/rpi/rpi.env
env_file_cfg:=board/raspberrypi/rpi/rpi.env
uboot_cfg:=$(uboot_src)/.config
dtb_dir:=$(wrkdir_plat_imgs)/broadcom

$(uboot_src):
	@$(call print_msg,>> U-BOOT: Downloading...)
	git clone --depth 1 --branch $(uboot_version) $(uboot_repo) $(uboot_src)

define build-uboot
$(strip $1): $(uboot_src)
	@$(call print_msg,>> U-BOOT: Configuring...)
	$(MAKE) -C $(uboot_src) $(strip $2)
#	@echo $(strip $3) >> $(uboot_src)/.config
	@$(call print_msg,>> U-BOOT: Modifying environment...)
# Uboot config
#	@printf "CONFIG_OF_SEPARATE=n\n" >> $(uboot_cfg)
#	@printf "CONFIG_OF_EMBED=y\n" >> $(uboot_cfg)
#	@printf "CONFIG_OF_OMIT_DTB=n\n" >> $(uboot_cfg)
#	@printf "CONFIG_OF_BOARD=n\n" >> $(uboot_cfg)
#	@printf "CONFIG_OF_HAS_PRIOR_STAGE=n\n" >> $(uboot_cfg)
#	@printf "CONFIG_SPECIFY_CONSOLE_INDEX=y\n" >> $(uboot_cfg)
#	@printf "CONFIG_CONS_INDEX=5\n" >> $(uboot_cfg)
# CONFIG_OF_BOARD is not set
# CONFIG_OF_HAS_PRIOR_STAGE=y
#CONFIG_SPECIFY_CONSOLE_INDEX=y
#CONFIG_CONS_INDEX=1
#	@printf "CONFIG_BOOTDELAY=5\n" >> $(uboot_cfg)
#	@printf "CONFIG_ENV_SOURCE_FILE=\"$(env_file_cfg)\"\n" >> $(uboot_cfg)
# Env file
	@printf "\n\nbootcmd_fatload=fatload mmc 0 $(uboot_load_bin_addr) $(uboot_load_bin); go $(uboot_load_bin_addr)\n" >> $(env_file)
	@printf "bootcmd=run bootcmd_fatload\n" >> $(env_file)
# Make
	@$(call print_msg,>> U-BOOT: Building...)
	$(MAKE) -C $(uboot_src) -j$(nproc)
# Copy
	@$(call print_msg,>> U-BOOT: Copying u-boot.bin...)
	cp $(uboot_src)/u-boot.bin $$@
#	mkdir -p $(dtb_dir)
#	cp -v $(uboot_src)/dts/dt.dtb $(dtb_dir)/bcm2711-rpi-4-b.dtb
#	cp  $(uboot_src)/dts/dt.dtb $(wrkdir_plat_imgs)/u-boot.dtb
#	read -p "Hello"
endef


u-boot: $(wrkdir_plat_imgs)/u-boot.bin

###
# git clone --depth 1 --branch $(uboot_version) $(uboot_repo) $(uboot_src)
# $(MAKE) -C $(uboot_src) qemu_arm64_defconfig
# echo "CONFIG_SYS_TEXT_BASE=0x60000000\nCONFIG_TFABOOT=y\n" >> uboot_src:=$(wrkdir_src)/u-boot
# $(MAKE) -C $(uboot_src) -j$(nproc) 
# cp $(uboot_src)/u-boot.bin $$@


# Include common function
include $(bao_demos)/common.mk

#### Variables #############
guests_dir := $(bao_demos)/guests/px4
lloader_dir:=$(guests_dir)/lloader
br_imgs_dir := $(guests_dir)/imgs

linux_repo?=https://github.com/raspberrypi/linux.git
linux_version?=stable_20241008
linux_src:=$(wrkdir_src)/linux-$(linux_version)
export LINUX_OVERRIDE_SRCDIR=$(linux_src) 


buildroot_repo:=https://github.com/buildroot/buildroot.git
buildroot_version:=2024.08.2
buildroot_src:=$(wrkdir_src)/buildroot-$(ARCH)-$(linux_version)
buildroot_img:=$(br_imgs_dir)/Image-$(PLATFORM)
PKG_DIR := $(buildroot_src)/package
CONFIG_FILE := $(buildroot_src)/package/Config.in
buildroot_host_pkgconf:=$(buildroot_src)/output/host/aarch64-buildroot-linux-gnu

# Benchmark
eval_guests_dir=$(bao_demos)/eval/guests
eval_linux_dir=$(eval_guests_dir)/linux
eval_interf_dir=$(eval_guests_dir)/interf
mibench_src=$(eval_linux_dir)/mibench

########### Functions ##################
define build-br-img
br-img-$(strip $1) $(buildroot_img)-$(strip $1): | $(linux_src) $(buildroot_src) $(if $(strip $2), cam-apps)
	@$(call print_msg,>> Building BR image: $(strip $1))
	@$(call update-linux-base-dir,$(strip $3)) # Dynamically update the base directory
#	export BAO_DEMOS_LINUX_CFG_FRAG="$(linux_cfg_frag)"
#	export BAO_DEMOS_ROOTFS_OVERLAY="$(buildroot_dir)/rootfs_overlays"
#	@$(call print_msg,>> BAO_DEMOS_ROOTFS_OVERLAY: $(BAO_DEMOS_ROOTFS_OVERLAY))
ifeq ($(strip $(linux_patches)),)
	@$(call print_msg,>> No patches to apply)
else
	@$(call print_msg,>> Applying patches: $(linux_patches))
# Check if the patch applies cleanly
	@if git -C "$(linux_src)" apply --check $(linux_patches); then \
		echo "Applying patch..."; \
		git -C "$(linux_src)" apply $(linux_patches); \
	else \
		echo "Patch does not apply cleanly. It might already be applied or conflict with the current code."; \
	fi
endif
	@$(call print_msg,>> BUILDROOT: deep clean)
	$(MAKE) -C $(buildroot_src) distclean
	@$(call print_msg,>> BUILDROOT: updating config)
	@$(call update-buildroot-cfg)
	$(MAKE) -C $(buildroot_src) defconfig BR2_DEFCONFIG=$(buildroot_defcfg)
#	@$(call wait_key)
	@$(call print_msg,>> BUILDROOT: copy benchmarks)
	@$(call cp-mibench)
	@$(call cp-boot-test)
	@$(call print_msg,>> BUILDROOT: reconfigure Linux kernel and build)
	$(MAKE) -C $(buildroot_src) linux-reconfigure all
	@$(call print_msg,>> BUILDROOT: copying image for backup...)
	@mkdir -p $(br_imgs_dir)
	cp $(buildroot_src)/output/images/Image "$(buildroot_img)-$(strip $1)"
endef

define build-linux
$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb: $(strip $2)
	@$(call print_msg,DTC: Building dtb $(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb)
	dtc -@ $$< > $$@

$(strip $1): $(buildroot_img)-$(strip $3) $(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb
	@$(call print_msg,LLOADER: Wrapping $(buildroot_img)-$(strip $3))
	$(MAKE) -C $(lloader_dir) ARCH=$(ARCH) \
		IMAGE=$(buildroot_img)-$(strip $3) \
		DTB=$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb \
		TARGET=$$(basename $$@)
endef

# Updating Linux directories and printing them
define update-linux-base-dir
	$(eval linux_base_dir := $(strip $1))
	$(eval buildroot_dir := $(linux_base_dir)/buildroot)
	$(eval linux_cfg_frag := $(wildcard $(linux_base_dir)/configs/*.config))
	$(eval linux_patches := $(wildcard $(linux_base_dir)/patches/$(linux_version)/*.patch))
	$(eval buildroot_defcfg := $(buildroot_dir)/$(ARCH).config)
	$(eval CAM_PKGS := $(buildroot_dir)/cam/libcamera-rpi)
	$(eval CAM_PKGS += $(buildroot_dir)/cam/rpicam-apps)
	@$(call print_msg,Linux base dir: $(linux_base_dir))
	@$(call print_msg,BR dir: $(buildroot_dir))
	@$(call print_msg,BR defconfig: $(buildroot_defcfg))
	@$(call print_msg,CAM PKGS: $(CAM_PKGS))
endef

# Update buildroot config without duplicates
define update-buildroot-cfg
	@sed -i "s|^BR2_ROOTFS_OVERLAY=.*|BR2_ROOTFS_OVERLAY=\"$(buildroot_dir)/rootfs_overlays\"|" $(buildroot_defcfg) || \
		printf "BR2_ROOTFS_OVERLAY=\"$(buildroot_dir)/rootfs_overlays\"\n" >> $(buildroot_defcfg)
	@sed -i "s|^BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=.*|BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\"$(linux_cfg_frag)\"|" $(buildroot_defcfg) || \
		printf "BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\"$(linux_cfg_frag)\"\n" >> $(buildroot_defcfg)
endef

########### Rules ###############
# Target to copy packages into buildroot
copy-cam-packages:
	@[ -n "$(CAM_PKGS)" ] || { echo "Error: PACKAGES is not defined."; exit 1; }
	@for pkg in $(CAM_PKGS); do \
		pkg_name=$$(basename $$pkg); \
		if [ ! -d "$(PKG_DIR)/$$pkg_name" ]; then \
			echo ">> Copying $$pkg_name to $(PKG_DIR)"; \
			cp -r "$$pkg" "$(PKG_DIR)/"; \
		fi \
	done

# Target to add config entries into buildroot
add-cam-config:
	@if ! grep -q 'source "package/libcamera-rpi/Config.in"' $(CONFIG_FILE); then \
		echo "Adding libcamera-rpi and rpicam-apps to $(CONFIG_FILE)"; \
		sed -i '/menu "Multimedia"/a \    source "package/libcamera-rpi/Config.in"\n    source "package/rpicam-apps/Config.in"' $(CONFIG_FILE); \
	fi

install-cam-requirements:
	@pip install -r $(buildroot_dir)/requirements.txt

setup-cam-build:
	@export PKG_CONFIG_SYSROOT_DIR=$(buildroot_host_pkgconf)/sysroot
	@export PKG_CONFIG_PATH=$(buildroot_host_pkgconf)/sysroot/usr/lib/pkgconfig

cam-apps: copy-cam-packages add-cam-config install-cam-requirements setup-cam-build

$(linux_src):
	git clone --depth 1 --branch $(linux_version) $(linux_repo) $(linux_src)

$(buildroot_src):
	git clone --depth 1 --branch $(buildroot_version) $(buildroot_repo)\
		$(buildroot_src)

clean-dtb:
	-rm $(wrkdir_demo_imgs)/*.dtb


define build-mibench
	@echo "Mibench: Building..."
	$(MAKE) -C $(mibench_src) ARCH=arm64 CROSS_COMPILE=$(buildroot_src)/output/host/bin/aarch64-linux-
	@$(call cp-mibench)
endef

define build-boot-test
	@echo "Boot test: building..."
	@$(buildroot_src)/output/host/bin/aarch64-linux-gcc $(eval_linux_dir)/boot_test.c -o $(eval_linux_dir)/boot_test
	@$(call cp-boot-test)
endef

define build-interf
	@echo ">> Interf guest: cleaning..."
	$(MAKE) -C $(eval_interf_dir) clean
	@echo ">> Interf guest: building..."
	$(MAKE) -C $(eval_interf_dir) PLATFORM=rpi4 CROSS_COMPILE=aarch64-none-elf-
	@$(call cp-interf)
endef

define cp-mibench
	@echo "Mibench: Copying files..."
	@cp -r $(mibench_src) $(buildroot_dir)/rootfs_overlays/root/
endef

define cp-boot-test
	@echo "Boot test: Copying..."
	@cp -v $(eval_linux_dir)/boot_test $(buildroot_dir)/rootfs_overlays/root/
endef

define cp-interf
	@echo "Interf guest: Copying..."
	@cp -v $(eval_interf_dir)/build/rpi4/baremetal.bin $(wrkdir_plat_imgs)/$(DEMO)
endef

define test-bench-build
	@echo "Benchmarks tools: building..."
	mkdir -vp $(buildroot_dir)/rootfs_overlays/root/
	mkdir -vp $(buildroot_dir)/rootfs_overlays/bin/
	@$(call build-mibench)
#	@$(call wait_key)
	@$(call build-boot-test)
endef

test-bench:
#	@$(call test-bench-build)
#	@$(call cp-interf)
#	ls $(wrkdir_plat_imgs)
	@$(call build-interf)

interf-build:
	@$(call build-interf)


# mibench-deploy:
# 	@echo "Deploying mibench"
# 	cp -r $(bao_demos)/eval/guests/linux/mibench 


.PHONY: cam-apps setup-cam-build install-cam-requirements copy-cam-packages add-cam-config test-bench

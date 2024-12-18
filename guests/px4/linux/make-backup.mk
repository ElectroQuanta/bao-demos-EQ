#### Variables #############
linux_dir := $(bao_demos)/guests/px4/
lloader_dir:=$(linux_dir)/lloader

#linux_repo?=https://github.com/torvalds/linux.git
#linux_version?=v6.10
#linux_version?=stable_20240124
linux_repo?=https://github.com/raspberrypi/linux.git
linux_version?=stable_20241008
linux_src:=$(wrkdir_src)/linux-$(linux_version)
export LINUX_OVERRIDE_SRCDIR=$(linux_src) 


buildroot_repo:=https://github.com/buildroot/buildroot.git
#buildroot_version:=2024.02.3
#buildroot_version:=2024.05.2
buildroot_version:=2024.08.2
#buildroot_version:=2022.11
buildroot_src:=$(wrkdir_src)/buildroot-$(ARCH)-$(linux_version)
buildroot_image:=$(buildroot_src)/output/images/Image-$(PLATFORM)
PKG_DIR := $(buildroot_src)/package
CONFIG_FILE := $(buildroot_src)/package/Config.in


linux_base_dir := $(bao_demos)/guests/px4/linux1
buildroot_dir := $(linux_base_dir)/buildroot


linux_cfg_frag:=$(wildcard $(linux_base_dir)/configs/base.config\
	$(linux_base_dir)/configs/$(ARCH).config\
	$(linux_base_dir)/configs/$(PLATFORM).config\
	$(linux_base_dir)/configs/debug.config)
linux_patches:=$(wildcard $(linux_base_dir)/patches/$(linux_version)/*.patch)

export BAO_DEMOS_LINUX_CFG_FRAG=$(linux_cfg_frag)
export BAO_DEMOS_ROOTFS_OVERLAY=$(buildroot_dir)/rootfs_overlays

buildroot_defcfg:=$(linux_base_dir)/buildroot/$(ARCH).config
buildroot_host_pkgconf:=$(buildroot_src)/output/host/aarch64-buildroot-linux-gnu

BR_IMGS_DIR := $(linux_base_dir)/buildroot/imgs

################################
########### Rules ###############

# Define package names
BR_SRC_APPS_DIR := $(buildroot_dir)/cam
PACKAGES := $(BR_SRC_APPS_DIR)/libcamera-rpi $(BR_SRC_APPS_DIR)/rpicam-apps

# Target to copy packages into buildroot
copy-cam-packages:
	@for pkg in $(PACKAGES); do \
		pkg_name=$$(basename $$pkg); \
		if [ ! -d "$(PKG_DIR)/$$pkg_name" ]; then \
			echo "Copying $$pkg_name to $(PKG_DIR)"; \
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
	@pip install -r $(linux_base_dir)/buildroot/requirements.txt

setup-cam-build:
	@export PKG_CONFIG_SYSROOT_DIR=$(buildroot_host_pkgconf)/sysroot
	@export PKG_CONFIG_PATH=$(buildroot_host_pkgconf)/sysroot/usr/lib/pkgconfig
#export CFLAGS="--sysroot=/home/zmp/Documents/br-main/buildroot-2024.02.3/output/host/aarch64-buildroot-linux-gnu/sysroot"
#export CXXFLAGS="--sysroot=/home/zmp/Documents/br-main/buildroot-2024.02.3/output/host/aarch64-buildroot-linux-gnu/sysroot"
#export LDFLAGS="--sysroot=/home/zmp/Documents/br-main/buildroot-2024.02.3/output/host/aarch64-buildroot-linux-gnu/sysroot"
#export PYTHONPATH="/home/zmp/Documents/br-main/buildroot-2024.02.3/output/host/aarch64-buildroot-linux-gnu/sysroot/usr/lib/python3.11/site-packages"

# build-cam-apps:
# 	@echo "BR2_PACKAGE_BOOST=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_GNUTLS=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_OPENSSL=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_TIFF=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_PYTHON_PYYAML=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_HOST_PYTHON_PYYAML=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_PYTHON_PYBIND=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_PYTHON_JINJA2=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_LIBGLIB=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_YAML=y" >> $(buildroot_src)/output/.config
# 	@echo "BR2_PACKAGE_LIBCAMERA_RPI=y" >> $(buildroot_src)/output/.config
# #	@echo "BR2_PACKAGE_RPICAM_APPS=y" >> $(buildroot_src)/output/.config
# 	$(MAKE) -C $(buildroot_src) olddefconfig
# 	$(MAKE) -C $(buildroot_src) libyaml
# 	$(MAKE) -C $(buildroot_src) libcamera-rpi
# #	$(MAKE) -C $(buildroot_src) rpicam-apps
# 	$(MAKE) -C $(buildroot_src) all

# Ensure cam-apps runs only after linux_src and buildroot_src are ready
#cam-apps: | $(linux_src) $(buildroot_src)
# cam-apps: copy-cam-packages add-cam-config install-cam-requirements setup-cam-build build-cam-apps
cam-apps: copy-cam-packages add-cam-config install-cam-requirements setup-cam-build

$(linux_src):
	git clone --depth 1 --branch $(linux_version) $(linux_repo) $(linux_src)
	@if [ -n "$(linux_patches)" ]; then \
		echo "Applying patches: $(linux_patches)"; \
		git -C $(linux_src) apply $(linux_patches); \
	else \
		echo "No patches to apply"; \
	fi

$(buildroot_src):
	git clone --depth 1 --branch $(buildroot_version) $(buildroot_repo)\
		$(buildroot_src)

linux $(buildroot_image): $(linux_patches) $(linux_cfg_frag) $(buildroot_defcfg) | $(linux_src) $(buildroot_src) cam-apps 
	$(MAKE) -C $(buildroot_src) distclean
	$(MAKE) -C $(buildroot_src) defconfig BR2_DEFCONFIG=$(buildroot_defcfg)
#	$(MAKE) -C $(buildroot_src) olddefconfig
#	$(MAKE) -C $(buildroot_src) menuconfig
	$(MAKE) -C $(buildroot_src) linux-reconfigure all
	mv $(buildroot_src)/output/images/*Image $(buildroot_image)

clean-dtb:
	-rm $(wrkdir_demo_imgs)/*.dtb

define build-linux
$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb: $(strip $2)
	dtc -@ $$< > $$@
$(strip $1): $(buildroot_image) $(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb
	$(MAKE) -C $(lloader_dir) ARCH=$(ARCH) IMAGE=$(buildroot_image)\
		DTB=$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb TARGET=$$(basename $$@)
endef

# Debug rule
# linux_elf: $(wrkdir_demo_imgs)/linux.bin
# 	$(CROSS_COMPILE)objcopy -I binary -O elf64-littleaarch64 \
# 	--binary-architecture aarch64 $(wrkdir_demo_imgs)/linux.bin linux.elf


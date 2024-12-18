#### Variables #############
linux_dir := $(bao_demos)/guests/px4/
lloader_dir:=$(linux_dir)/lloader

linux_repo?=https://github.com/raspberrypi/linux.git
linux_version?=stable_20241008
linux_src:=$(wrkdir_src)/linux-$(linux_version)
export LINUX_OVERRIDE_SRCDIR=$(linux_src) 


buildroot_repo:=https://github.com/buildroot/buildroot.git
buildroot_version:=2024.08.2
buildroot_src:=$(wrkdir_src)/buildroot-$(ARCH)-$(linux_version)
buildroot_image:=$(buildroot_src)/output/images/Image-$(PLATFORM)
PKG_DIR := $(buildroot_src)/package
CONFIG_FILE := $(buildroot_src)/package/Config.in
buildroot_host_pkgconf := $(buildroot_src)/output/host/aarch64-buildroot-linux-gnu

################################
########### Rules ###############

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

update-linux-base-dir = \
	$(eval linux_base_dir := $(1)) \
	$(eval buildroot_dir := $(linux_base_dir)/buildroot) \
	$(eval linux_cfg_frag := $(wildcard $(linux_base_dir)/configs/*.config)) \
	$(eval linux_patches := $(wildcard $(linux_base_dir)/patches/$(linux_version)/*.patch)) \
	$(eval buildroot_defcfg := $(linux_base_dir)/buildroot/$(ARCH).config) \
	$(eval buildroot_image := $(linux_base_dir)/output/images/linux.bin)

# Set up the environment for the first build
$(eval $(call update-linux-base-dir, $(linux_dir)/linux1))

# Define a build rule for the first Linux image, without cam-apps
$(eval $(call build-rule, px4, ))

# Set up the environment for the second build
$(eval $(call update-linux-base-dir, $(linux_dir/linux2)))

# Define a build rule for the second Linux image, with cam-apps
$(eval $(call build-rule, cam, 1))


define build-rule
.PHONY: linux-$(1)

linux-$(1): | $(linux_src) $(buildroot_src) $(if $(2), cam-apps)
	$(MAKE) -C $(buildroot_src) distclean
	$(MAKE) -C $(buildroot_src) defconfig BR2_DEFCONFIG=$(buildroot_defcfg)
	$(MAKE) -C $(buildroot_src) linux-reconfigure all
	mv $(buildroot_src)/output/images/*Image $(buildroot_image)
	mv $(buildroot_image) $(wrkdir_bin)/
endef

# Targets
all: linux-px4 linux-cam

clean-dtb:
	-rm $(wrkdir_demo_imgs)/*.dtb

define build-linux
$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb: $(strip $2)
	dtc -@ $$< > $$@
$(strip $1): $(buildroot_image) $(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb
	$(MAKE) -C $(lloader_dir) ARCH=$(ARCH) IMAGE=$(buildroot_image)\
		DTB=$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb TARGET=$$(basename $$@)
endef

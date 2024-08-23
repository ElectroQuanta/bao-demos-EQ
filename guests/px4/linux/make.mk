linux_base_dir := $(bao_demos)/guests/px4/linux

#linux_repo?=https://github.com/torvalds/linux.git
#linux_version?=v6.1
linux_repo?=https://github.com/raspberrypi/linux.git
#linux_version?=stable_20240529 # v6.6
linux_version?=stable_20240124
linux_src:=$(wrkdir_src)/linux-$(linux_version)
linux_cfg_frag:=$(wildcard $(linux_base_dir)/configs/base.config\
	$(linux_base_dir)/configs/$(ARCH).config\
	$(linux_base_dir)/configs/$(PLATFORM).config)
linux_patches:=$(wildcard $(linux_base_dir)/patches/$(linux_version)/*.patch)
export LINUX_OVERRIDE_SRCDIR=$(linux_src) 
export BAO_DEMOS_LINUX_CFG_FRAG=$(linux_cfg_frag)

$(linux_src):
	git clone --depth 1 --branch $(linux_version) $(linux_repo) $(linux_src)
#git -C $(linux_src) apply $(linux_patches)

buildroot_repo:=https://github.com/buildroot/buildroot.git
buildroot_version:=2024.02.3
#buildroot_version:=2022.11
buildroot_src:=$(wrkdir_src)/buildroot-$(ARCH)-$(linux_version)
buildroot_defcfg:=$(linux_base_dir)/buildroot/$(ARCH).config

$(buildroot_src):
	git clone --depth 1 --branch $(buildroot_version) $(buildroot_repo)\
		$(buildroot_src)

buildroot_image:=$(buildroot_src)/output/images/Image-$(PLATFORM)

linux $(buildroot_image): $(linux_patches) $(linux_cfg_frag) $(buildroot_defcfg) | $(linux_src) $(buildroot_src) 
	$(MAKE) -C $(buildroot_src) defconfig BR2_DEFCONFIG=$(buildroot_defcfg)
	$(MAKE) -C $(buildroot_src) linux-reconfigure all
	mv $(buildroot_src)/output/images/*Image $(buildroot_image)

lloader_dir:=$(linux_base_dir)/lloader


clean-dtb:
	rm $(wrkdir_demo_imgs)/linux.dtb

define build-linux
$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb: $(strip $2)
	dtc -@ $$< > $$@
$(strip $1): $(buildroot_image) $(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb
	$(MAKE) -C $(lloader_dir) ARCH=$(ARCH) IMAGE=$(buildroot_image)\
		DTB=$(wrkdir_demo_imgs)/$(basename $(notdir $2)).dtb TARGET=$$(basename $$@)
endef

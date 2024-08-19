#atf_repo:=https://github.com/bao-project/arm-trusted-firmware.git
#atf_version:=bao/demo
atf_repo:=https://github.com/ARM-software/arm-trusted-firmware.git
atf_src:=$(wrkdir_src)/atf-$(ARCH)
atf_version:=lts-v2.10.4

$(atf_src):
	git clone --depth 1 --branch $(atf_version) $(atf_repo) $(atf_src)

define build-atf
$(strip $1): $(atf_src)
	$(MAKE) -C $(atf_src) bl31 PLAT=$(strip $2) $(strip $3)
	cp $(atf_src)/build/$(strip $2)/release/bl31.bin $$@
endef

SHELL:=/bin/bash

########## Check requirements
# PLATFORM, CROSS_COMPILE, DEMO, ARCH
bao_demos:=$(abspath .)
platform_dir:=$(bao_demos)/platforms/$(PLATFORM)
demo_dir:=$(bao_demos)/demos/$(DEMO)

# Include common function
include $(bao_demos)/common.mk

ifeq ($(filter clean distclean, $(MAKECMDGOALS)),)
ifndef CROSS_COMPILE
 $(error No CROSS_COMPILE prefix defined)
endif
endif

ifeq ($(filter distclean, $(MAKECMDGOALS)),)

ifndef PLATFORM
 $(error No target PLATFORM defined)
endif

ifeq ($(wildcard $(platform_dir)),)
 $(error Target platform $(PLATFORM) is not supported)
endif

ifndef DEMO
 $(error No target DEMO defined.)
endif

ifeq ($(wildcard $(demo_dir)),)
 $(error Target demo $(DEMO) is not supported)
endif

ifeq ($(wildcard $(demo_dir)/configs/$(PLATFORM).c),)
 $(error The $(DEMO) demo is not supported by the $(PLATFORM) platform)
endif

endif
##################################

################# utility functions
ifeq ($(NO_INSTRUCTIONS),)
define print-instructions
	@for i in {1..80}; do printf "-"; done ; printf "\n"
	@cat $(strip $1) | sed -n '/instruction#$(strip $2)/,/instruction#./p' |\
		sed '1d;$d' | head -n -1 |\
		sed -r -e 's/(.*)\[(.*)\]\((http.*)\)(.*)/\1\2 (\3)\4/g' |\
		sed -r -e 's/(.*)\[(.*)\]\((\.\/(\.\.\/)*)(.*)\)(.*)/\1\2 (\.\/\5)\6/g' |\
		pandoc --to plain --wrap=preserve | $(environment) envsubst
	-@if [ $(strip $3) = false ];\
		then  printf "\n(Press return to continue)\r"; read -s dummy;\
		else for i in {1..80}; do printf "-"; done ; printf "\n"; fi
endef
endif
########################################

################# setup working directories
wrkdir:=$(bao_demos)/wrkdir
wrkdir_src:=$(wrkdir)/srcs
wrkdir_bin:=$(wrkdir)/bin
wrkdir_imgs:=$(wrkdir)/imgs
wrkdir_plat_imgs:=$(wrkdir_imgs)/$(PLATFORM)
wrkdir_demo_imgs:=$(wrkdir_plat_imgs)/$(DEMO)
wrkdirs=$(wrkdir) $(wrkdir_src) $(wrkdir_bin) $(wrkdir_plat_imgs) $(wrkdir_demo_imgs)

environment:=BAO_DEMOS=$(bao_demos)
environment+=BAO_DEMOS_WRKDIR=$(wrkdir)
environment+=BAO_DEMOS_WRKDIR_SRC=$(wrkdir_src)
environment+=BAO_DEMOS_WRKDIR_PLAT=$(wrkdir_plat_imgs)
environment+=BAO_DEMOS_WRKDIR_IMGS=$(wrkdir_demo_imgs)
environment+=BAO_DEMOS_SDCARD=/run/media/$$USER/boot
environment+=BAO_DEMOS_SDCARD_DEV=/dev/sda


export BAO_DEMOS=$(bao_demos)
export BAO_DEMOS_WRKDIR=$(wrkdir)
export BAO_DEMOS_WRKDIR_SRC=$(wrkdir_src)
export BAO_DEMOS_WRKDIR_PLAT=$(wrkdir_plat_imgs)


all: platform 

#bao_repo:=https://github.com/bao-project/bao-hypervisor
#bao_version:=v1.0.0
bao_repo:=git@github.com:ElectroQuanta/bao-hypervisor-porting.git
bao_version:=rpi4/uart5
bao_src:=$(wrkdir_src)/bao
bao_cfg_repo:=$(wrkdir_demo_imgs)/config
wrkdirs+=$(bao_cfg_repo)
bao_cfg:=$(bao_cfg_repo)/$(DEMO).c
bao_image:=$(wrkdir_demo_imgs)/bao.bin

include $(platform_dir)/make.mk
include $(demo_dir)/make.mk

ifeq ($(filter clean distclean, $(MAKECMDGOALS)),)
$(shell mkdir -p $(wrkdirs))
endif

guests: $(guest_images)

$(bao_src):
	git clone --branch $(bao_version) $(bao_repo) $(bao_src)
	git -C $(bao_src) submodule init
	git -C $(bao_src) submodule update --recursive
#sed -i '20i\void uart_putc(volatile bao_uart_t *, const char );' $(bao_src)/src/core/console.c

$(bao_cfg): | $(bao_cfg_repo)
	cp -vL $(bao_demos)/demos/$(DEMO)/configs/$(PLATFORM).c $(bao_cfg)

bao $(bao_image): $(guest_images) $(bao_cfg) $(bao_src) 
	@$(call print_msg,BAO: Building from config $(bao_cfg_repo)/$(DEMO))
	bear -- $(MAKE) -C $(bao_src)\
		PLATFORM=$(PLATFORM)\
		CONFIG_REPO=$(bao_cfg_repo)\
		CONFIG=$(DEMO) \
		CPPFLAGS=-DBAO_DEMOS_WRKDIR_IMGS=$(wrkdir_demo_imgs)
	cp $(bao_src)/bin/$(PLATFORM)/$(DEMO)/bao.bin $(bao_image)

bao_clean:
	$(MAKE) -C $(bao_src) clean\
		PLATFORM=$(PLATFORM)\
		CONFIG_REPO=$(bao_cfg_repo)\
		CONFIG=$(DEMO)\
		CPPFLAGS=-DBAO_DEMOS_WRKDIR_IMGS=$(wrkdir_demo_imgs)

#platform: $(bao_image)
#	@echo "I'm the platform target being called"

#guests_clean bao_clean platform_clean:

firmware_clean:
	-@rm -vrf $(wrkdir)/imgs/$(PLATFORM)/firmware

atf_clean: 
	-@rm -v $(wrkdir)/imgs/$(PLATFORM)/bl31.bin

atf_distclean: 
	$(MAKE) -C $(wrkdir_src)/atf-$(ARCH) distclean

uboot_clean: 
	-@rm -v $(wrkdir)/imgs/$(PLATFORM)/u-boot.bin

uboot_distclean: 
	$(MAKE) -C $(wrkdir_src)/u-boot distclean

platform_clean: firmware_clean atf_clean uboot_clean

bao_distclean: bao_clean_cfg
	-@rm -vrf $(wrkdir_src)/bao

bao_clean_cfg:
	-@rm -vrf $(bao_cfg_repo)

baremetal_clean:
	-@rm -v $(wrkdir_imgs)/$(PLATFORM)/baremetal/baremetal.bin

clean: guests_clean bao_clean platform_clean
	-@rm -rf $(wrkdir)/imgs/$(PLATFORM)/$(DEMO)

distclean: clean-br-imgs
	@$(call print_msg,Cleaning working directory...)
	@if $(call confirm_action,Are you sure you want to remove WRKDIR); then \
		$(call print_msg,Proceeding with removal...); \
		rm -rf $(wrkdir); \
	else \
		$(call print_msg,Aborted by the user.); \
	fi

# .PHONY: all clean guests bao platform
.PHONY: firmware_clean atf_clean atf_distclean uboot_clean \
        uboot_distclean platform_clean bao_distclean bao_clean_cfg \
        baremetal_clean clean distclean clean-dtb clean-linux-bin \
        clean-br-px4-img clean-br-cam-img clean-br-imgs \
	    bao guests platform all
.NOTPARALLEL:

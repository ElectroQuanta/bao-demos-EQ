#atf_repo:=https://github.com/bao-project/arm-trusted-firmware.git
#atf_version:=bao/demo
atf_repo:=https://github.com/ARM-software/arm-trusted-firmware.git
atf_src:=$(wrkdir_src)/atf-$(ARCH)
atf_version:=lts-v2.10.4

$(atf_src):
	git clone --depth 1 --branch $(atf_version) $(atf_repo) $(atf_src)

define build-atf
$(strip $1): $(atf_src)
# Replace serial0 by serial5 (required by PilotPi)	
	sed -i 's/serial0/serial5/g' $(atf_src)/plat/rpi/rpi4/rpi4_bl31_setup.c
# Replace UART offset to point to serial5
	sed -i 's/#define RPI4_IO_PL011_UART_OFFSET\tULL(0x00201000)/#define RPI4_IO_PL011_UART_OFFSET\tULL(0x00201a00)/' $(atf_src)/plat/rpi/rpi4/include/rpi_hw.h
	$(MAKE) -C $(atf_src) bl31 PLAT=$(strip $2) $(strip $3)
	cp $(atf_src)/build/$(strip $2)/release/bl31.bin $$@
endef

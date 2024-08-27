# Define your VMs
#VMS := linux1 linux2
#
## Include the Makefiles for each VM
#$(foreach vm,$(VMS),$(eval include $(bao_demos)/guests/px4/$(vm)/make.mk))
#
## Define paths for images and device trees
#VM_IMAGES := $(foreach vm,$(VMS),$(wrkdir_demo_imgs)/$(vm).bin)
#VM_DTS := $(foreach vm,$(VMS),$(bao_demos)/demos/$(DEMO)/devicetrees/$(PLATFORM)/$(vm).dts)
#
## Apply the build-linux function to each VM
#$(foreach vm,$(VMS),$(eval $(call build-linux,$(wrkdir_demo_imgs)/$(vm).bin,$(bao_demos)/demos/$(DEMO)/devicetrees/$(PLATFORM)/$(vm).dts)))
#
#guest_image := $(VM_IMAGES)

include $(bao_demos)/guests/px4/linux/make.mk

linux_image=$(wrkdir_demo_imgs)/linux.bin
linux_dts=$(bao_demos)/demos/$(DEMO)/devicetrees/$(PLATFORM)/linux.dts
$(eval $(call build-linux, $(linux_image), $(linux_dts)))


clean-linux-bin: clean-dtb
	-rm $(linux_image)
	-rm $(wrkdir_demo_imgs)/linux.elf

guest_images:=$(linux_image)

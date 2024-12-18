include $(bao_demos)/guests/px4/make.mk

###################### Dual
linux_dts_dir=$(bao_demos)/demos/$(DEMO)/devicetrees/$(PLATFORM)
linux_image1:=$(wrkdir_demo_imgs)/linux_px4.bin
linux_image2:=$(wrkdir_demo_imgs)/linux_cam.bin

# Define rules for px4 and cam buildroot images
$(eval $(call build-br-img,px4,,$(guests_dir)/linux-px4))
$(eval $(call build-br-img,cam,1,$(guests_dir)/linux-cam))

# Define targets for vm1 and vm2 binaries
$(eval $(call build-linux,$(linux_image1),$(linux_dts_dir)/linux_px4.dts,px4))
$(eval $(call build-linux,$(linux_image2),$(linux_dts_dir)/linux_cam.dts,cam))


# Group both images under the guest_images target
guest_images:=$(linux_image2)
guest_images+=$(linux_image1)
#guest_images: $(linux_image1) $(linux_image2)

# Clean rule for Linux binaries
clean-linux-bin: clean-dtb
	@$(call print_msg,Cleaning Binaries...)
	-@rm -f $(guest_images)
	-@rm -f $(wrkdir_demo_imgs)/*.elf
#	@if $(call confirm_action,Are you sure you want to remove guest binaries); then \
#		$(call print_msg,Proceeding with removal...); \
#		-@rm -f $(guest_images); \
#		-@rm -f $(wrkdir_demo_imgs)/*.elf; \
#	else \
#		$(call print_msg,Aborted by the user.); \
#	fi

clean-br-px4-img:
	@$(call print_msg,Cleaning Buildroot image for PX4...)
	@if $(call confirm_action,Are you sure you want to remove $(br_imgs_dir)/Image-$(PLATFORM)-px4?); then \
		$(call print_msg,Proceeding with removal...); \
		rm -f $(br_imgs_dir)/Image-$(PLATFORM)-px4; \
	else \
		$(call print_msg,Aborted by the user.); \
	fi

clean-br-cam-img:
	@$(call print_msg,Cleaning Buildroot image for Cam...)
	@if $(call confirm_action,Are you sure you want to remove $(br_imgs_dir)/Image-$(PLATFORM)-cam?); then \
		$(call print_msg,Proceeding with removal...); \
		rm -f $(br_imgs_dir)/Image-$(PLATFORM)-cam; \
	else \
		$(call print_msg,Aborted by the user.); \
	fi

clean-br-imgs: clean-br-px4-img clean-br-cam-img
	@$(call print_msg,All Buildroot images cleaned...)



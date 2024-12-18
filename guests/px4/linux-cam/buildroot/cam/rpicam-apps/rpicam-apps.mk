################################################################################
#
# rpicam-apps
#
################################################################################

RPICAM_APPS_VERSION = v1.5.1
RPICAM_APPS_SOURCE = $(RPICAM_APPS_VERSION).tar.gz
RPICAM_APPS_SITE = https://github.com/raspberrypi/rpicam-apps/archive/refs/tags
RPICAM_APPS_LICENSE = BSD-2
RPICAM_APPS_LICENSE_FILES = license.txt
RPICAM_APPS_INSTALL_STAGING = YES

#cmake libboost-program-options-dev libdrm-dev libexif-dev
RPICAM_APPS_DEPENDENCIES = \
	boost \
	libdrm \
	libpng \
	libexif

RPICAM_APPS_SOURCE_DIR = $(BUILD_DIR)/rpicam-apps-$(RPICAM_APPS_VERSION)
RPICAM_APPS_BUILD_DIR = $(RPICAM_APPS_SOURCE_DIR)/build

define gen_cross_file_rpicam
	@echo '>>>>>>>>>> Cross file: generating $(PKG_NAME)...'
	@echo "DIR: $(RPICAM_APPS_BUILD_DIR)"
	printf "%b" \
	"[binaries]\n" \
	"c = '$(TARGET_CROSS)gcc'\n" \
	"cpp = '$(TARGET_CROSS)g++'\n" \
	"ar = '$(TARGET_CROSS)ar'\n" \
	"strip = '$(TARGET_CROSS)strip'\n" \
	"python = '/home/zmp/OneDrive_UM/Documents/Univ/MI_Electro/Tese/Bao/bao-demos-vm/bao-venv/bin/python3'\n" \
	"pkg-config = '$(HOST_DIR)/bin/pkg-config'\n" \
	"cmake = '/usr/bin/cmake'\n" \
	"[host_machine]\n" \
	"system = 'linux'\n" \
	"cpu_family = 'aarch64'\n" \
	"cpu = '$(BR2_ARCH)'\n" \
	"endian = 'little'\n" \
	> "$(RPICAM_APPS_BUILD_DIR)/cross_file.txt"
	echo '>>>>>>>>>> Cross file: generated!!!'
endef

define RPICAM_APPS_PRECFG
	mkdir -p $(RPICAM_APPS_BUILD_DIR)
	$(gen_cross_file_rpicam)
endef

# Set up the environment variables
define RPICAM_APPS_CONFIGURE_ENV
	export PKG_CONFIG_PATH=$(STAGING_DIR)/usr/lib/pkgconfig:$(PKG_CONFIG_PATH)
	export CMAKE_PREFIX_PATH=$(STAGING_DIR)/usr
endef

# meson setup build -Denable_libav=disabled -Denable_drm=enabled -Denable_egl=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled
RPICAM_APPS_CONF_OPTS = \
	--prefix=/usr \
	--cross-file=$(RPICAM_APPS_BUILD_DIR)/cross_file.txt \
	--buildtype=release \
	--wrap-mode=forcefallback \
	-Denable_libav=disabled \
	-Denable_drm=enabled \
	-Denable_egl=disabled \
	-Denable_qt=disabled \
	-Denable_opencv=disabled \
	-Denable_tflite=disabled \
	$(RPICAM_APPS_BUILD_DIR) \
	$(RPICAM_APPS_SOURCE_DIR)

define RPICAM_APPS_CONFIGURE_CMDS
	$(RPICAM_APPS_PRECFG)
	@echo "Configuring..."
	$(RPICAM_APPS_CONFIGURE_ENV)
	cd $(RPICAM_APPS_BUILD_DIR)
	$(HOST_DIR)/bin/meson setup $(RPICAM_APPS_CONF_OPTS)
endef

define fix_python_include_rpicam
	sed -i 's|-I/usr/include/python3.12||g' $(RPICAM_APPS_BUILD_DIR)/build.ninja
endef

define RPICAM_APPS_BUILD_CMDS
	@echo ">> Fixing Python includes"
	$(fix_python_include_rpicam)
	@echo ">> Build $(PKG_NAME)..."
	$(RPICAM_APPS_CONFIGURE_ENV)
	$(HOST_DIR)/bin/ninja -C $(RPICAM_APPS_BUILD_DIR)
	@echo ">> $(PKG_NAME)$ build!!!"
endef

# RPICAM_APPS_INSTALL_TARGET_CMDS is defined by default
define RPICAM_APPS_INSTALL_TARGET_CMDS
	DESTDIR=$(TARGET_DIR) $(HOST_DIR)/bin/ninja -C $(RPICAM_APPS_BUILD_DIR) install
# Install the .pc file manually if not installed by ninja
#cp -v $(RPICAM_APPS_BUILD_DIR)/meson-private/libcamera.pc $(TARGET_DIR)/usr/lib/pkgconfig/
endef

$(eval $(meson-package))

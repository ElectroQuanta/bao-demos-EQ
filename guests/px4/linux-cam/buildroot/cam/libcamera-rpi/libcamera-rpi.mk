################################################################################
#
# libcamera-rpi
#
################################################################################

#LIBCAMERA_RPI_VERSION = v0.3.0+rpt20240617
LIBCAMERA_RPI_VERSION = v0.3.2+rpt20241112
LIBCAMERA_RPI_SOURCE = $(LIBCAMERA_RPI_VERSION).tar.gz
LIBCAMERA_RPI_SITE = https://github.com/raspberrypi/libcamera/archive/refs/tags
LIBCAMERA_RPI_LICENSE = LGPL-2.1-or-later
LIBCAMERA_RPI_LICENSE_FILES = LICENSES/LGPL-2.1-or-later.txt
LIBCAMERA_RPI_INSTALL_STAGING = YES

LIBCAMERA_RPI_DEPENDENCIES = \
	boost \
	gnutls \
	openssl \
	tiff \
	python3 \
	libglib2 \
	libyaml \
	gstreamer1 \
	python-pyyaml \
	python-jinja2 \
	python-pybind

LIBCAMERA_RPI_SOURCE_DIR = $(BUILD_DIR)/libcamera-rpi-$(LIBCAMERA_RPI_VERSION)
LIBCAMERA_RPI_BUILD_DIR = $(LIBCAMERA_RPI_SOURCE_DIR)/build

define gen_cross_file_libcam_rpi
	@echo '>>>>>>>>>> Cross file: generating $(PKG_NAME)...'
	@echo "DIR: $(LIBCAMERA_RPI_BUILD_DIR)"
	printf "%b" \
	"[binaries]\n" \
	"c = '$(TARGET_CROSS)gcc'\n" \
	"cpp = '$(TARGET_CROSS)g++'\n" \
	"ar = '$(TARGET_CROSS)ar'\n" \
	"strip = '$(TARGET_CROSS)strip'\n" \
	"python = '$(VIRTUAL_ENV)/bin/python3'\n" \
	"pkg-config = '$(HOST_DIR)/bin/pkg-config'\n" \
	"cmake = '/usr/bin/cmake'\n" \
	"[host_machine]\n" \
	"system = 'linux'\n" \
	"cpu_family = 'aarch64'\n" \
	"cpu = '$(BR2_ARCH)'\n" \
	"endian = 'little'\n" \
	> "$(LIBCAMERA_RPI_BUILD_DIR)/cross_file.txt"
	echo '>>>>>>>>>> Cross file: generated!!!'
endef

define LIBCAMERA_RPI_PRECFG
	mkdir -p $(LIBCAMERA_RPI_BUILD_DIR)
	$(gen_cross_file_libcam_rpi)
endef

LIBCAMERA_RPI_CONF_OPTS = \
	--prefix=/usr \
	--cross-file=$(LIBCAMERA_RPI_BUILD_DIR)/cross_file.txt \
	--buildtype=release \
	--wrap-mode=forcefallback \
	-Dpipelines=rpi/vc4,rpi/pisp \
	-Dipas=rpi/vc4,rpi/pisp \
	-Dv4l2=true \
	-Dgstreamer=enabled \
	-Dtest=false \
	-Dlc-compliance=disabled \
	-Dcam=disabled \
	-Dqcam=disabled \
	-Ddocumentation=disabled \
	-Dpycamera=enabled \
	$(LIBCAMERA_RPI_BUILD_DIR) \
	$(LIBCAMERA_RPI_SOURCE_DIR)

define LIBCAMERA_RPI_CONFIGURE_CMDS
	$(LIBCAMERA_RPI_PRECFG)
	@echo "Configuring..."
	$(HOST_DIR)/bin/meson setup $(LIBCAMERA_RPI_CONF_OPTS)
endef

define fix_python_include_libcam_rpi
	sed -i 's|-I/usr/include/python3.12||g' $(LIBCAMERA_RPI_BUILD_DIR)/build.ninja
endef

define LIBCAMERA_RPI_BUILD_CMDS
	@echo ">> Fixing Python includes"
	$(fix_python_include_libcam_rpi)
	@echo ">> Build libcamera..."
	$(HOST_DIR)/bin/ninja -C $(LIBCAMERA_RPI_BUILD_DIR)
	@echo ">> libcamera build!!!"
endef

# LIBCAMERA_RPI_INSTALL_TARGET_CMDS is defined by default
define LIBCAMERA_RPI_INSTALL_TARGET_CMDS
	DESTDIR=$(TARGET_DIR) $(HOST_DIR)/bin/ninja -C $(LIBCAMERA_RPI_BUILD_DIR) install
# Install the .pc file manually if not installed by ninja
#cp -v $(LIBCAMERA_RPI_BUILD_DIR)/meson-private/libcamera.pc $(TARGET_DIR)/usr/lib/pkgconfig/
endef

$(eval $(meson-package))

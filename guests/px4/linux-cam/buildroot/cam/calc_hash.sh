#!/bin/bash

LIBCAMERA_RPI_VERSION=v0.3.2+rpt20241112
LIBCAMERA_RPI_SOURCE=${LIBCAMERA_RPI_VERSION}.tar.gz
LIBCAMERA_RPI_SITE=https://github.com/raspberrypi/libcamera/archive/refs/tags
#LIBCAMERA_RPI_LINK="${LIBCAMERA_RPI_SITE}/${LIBCAMERA_RPI_SOURCE}"

RPICAM_APPS_VERSION=v1.5.1
RPICAM_APPS_SOURCE=${RPICAM_APPS_VERSION}.tar.gz
RPICAM_APPS_SITE=https://github.com/raspberrypi/rpicam-apps/archive/refs/tags

download_gunzip(){
	local pkg="$1"
    # Evaluate the value of the variable named "${pkg}_SITE"
    pkg_site=$(eval echo "\${${pkg}_SITE}")
    pkg_src=$(eval echo "\${${pkg}_SOURCE}")
	local link="${pkg_site}/${pkg_src}"

	echo "site: ${pkg_site}"
	echo "src: ${pkg_src}"
	echo "link: ${link}"

# Check if file already exists, otherwise download it
	if [ ! -f "${pkg_src}" ]; then
	   echo "Downloading ${pkg}..."
	   wget -O "${pkg_src}" "${link}"
	else
		echo "${pkg} gunzip already exists..."
	fi
}

download_gunzip "LIBCAMERA_RPI"
download_gunzip "RPICAM_APPS"

#sha256sum ${LIBCAM_RPI_SOURCE} > libcam_calc.hash

#
# Copyright 2026, UNSW
#
# SPDX-License-Identifier: BSD-2-Clause
#
IPBENCH2_VERSION = 2.1.3
IPBENCH2_SITE = $(call github,au-ts,ipbench,main)
IPBENCH2_SUBDIR = ipbench2
IPBENCH2_LICENSE = GPL-2.0
IPBENCH2_LICENSE_FILES = COPYING

IPBENCH2_INSTALL_STAGING = YES

IPBENCH2_AUTORECONF = YES
IPBENCH2_AUTORECONF_OPTS = -I$(HOST_DIR)/share/autoconf-archive

IPBENCH2_DEPENDENCIES = \
	host-swig \
	host-python3 \
	host-autoconf-archive \
	python3

IPBENCH2_CONF_OPTS = \
	--disable-static \
	--enable-shared

# configure.ac declares AC_CONFIG_MACRO_DIR([m4]) but the empty m4/
# directory is not shipped in the git tarball, so aclocal aborts during
# autoreconf. Create it before the configure step runs.
define IPBENCH2_CREATE_M4_DIR
	mkdir -p $(@D)/$(IPBENCH2_SUBDIR)/m4
endef
IPBENCH2_PRE_CONFIGURE_HOOKS += IPBENCH2_CREATE_M4_DIR

$(eval $(autotools-package))

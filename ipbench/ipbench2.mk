# ipbench2 for Buildroot
IPBENCH2_VERSION = 2.1.1
IPBENCH2_SITE = $(call github,au-ts,ipbench,crosscompilation)
IPBENCH2_SUBDIR = ipbench2
IPBENCH2_INSTALL_STAGING = YES
IPBENCH2_LICENSE = GPL-2.0
IPBENCH2_LICENSE_FILES = COPYING
IPBENCH2_DEPENDENCIES = host-swig host-python3 host-libtool

# Override autotools configure variables
IPBENCH2_CONF_ENV = \
    CC="$(TARGET_CC)" \
    CXX="$(TARGET_CXX)" \
    LD="$(TARGET_LD)" \
    LDFLAGS="$(TARGET_LDFLAGS)" \
    CFLAGS="$(TARGET_CFLAGS)" \
    CXXFLAGS="$(TARGET_CXXFLAGS)" \
    CROSS_COMPILE="$(TARGET_CROSS)" \
    LIBTOOL="$(LIBTOOL)" \
    PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" \
    PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \
    PKG_CONFIG_LIBDIR="$(STAGING_DIR)/usr/lib/pkgconfig"

define IPBENCH2_CONFIGURE_CMDS
    cd $(@D)/$(IPBENCH2_SUBDIR) && \
    $(TARGET_MAKE_ENV) ./autogen.sh && \
    $(TARGET_CONFIGURE_OPTS) \
    $(IPBENCH2_CONF_ENV) \
    ac_cv_path_CC=$(TARGET_CC) \
    ./configure \
        --build=$(GNU_HOST_NAME) \
        --host=$(GNU_TARGET_NAME) \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libdir=/usr/lib \
        --disable-static \
        --enable-shared \
        --with-sysroot=$(STAGING_DIR)
endef

# Fix libtool to handle cross-compilation paths
define IPBENCH2_POST_CONFIGURE_CMDS
    $(SED) "s,^CC=\"\$$CC\",CC=\"$(TARGET_CC)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,^LD=\"\$$LD\",LD=\"$(TARGET_LD)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,^NM=\"/usr/bin/nm -B\",NM=\"$(TARGET_NM)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,-L/usr/lib[^[:space:]]*,,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,-L/lib[^[:space:]]*,,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,\$${wl}-rpath \$${wl}/usr/lib,,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) 's,^runpath_var=.*,runpath_var=,' $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) 's,^sys_lib_search_path_spec=.*,sys_lib_search_path_spec="$(STAGING_DIR)/usr/lib",' $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) 's,^sys_lib_dlsearch_path_spec=.*,sys_lib_dlsearch_path_spec="$(STAGING_DIR)/usr/lib",' $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,-L/usr/lib,-L$(STAGING_DIR)/usr/lib,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
endef

define IPBENCH2_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        CC="$(TARGET_CC)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        LDFLAGS="$(TARGET_LDFLAGS)" \
        -C $(@D)/$(IPBENCH2_SUBDIR)
endef

define IPBENCH2_INSTALL_TARGET_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        DESTDIR=$(TARGET_DIR) \
        -C $(@D)/$(IPBENCH2_SUBDIR) install
endef

define IPBENCH2_INSTALL_STAGING_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        DESTDIR=$(STAGING_DIR) \
        -C $(@D)/$(IPBENCH2_SUBDIR) install
endef

$(eval $(autotools-package))

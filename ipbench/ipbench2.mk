# ipbench2 for Buildroot

IPBENCH2_VERSION = 2.1.1
IPBENCH2_SITE = $(call github,au-ts,ipbench,main)
IPBENCH2_SUBDIR = ipbench2
IPBENCH2_INSTALL_STAGING = YES
IPBENCH2_LICENSE = GPL-2.0
IPBENCH2_LICENSE_FILES = COPYING

IPBENCH2_DEPENDENCIES = host-swig host-python3 host-libtool python3

IPBENCH2_INSTALL_TARGET = YES
IPBENCH2_KEEP_HEADERS = YES
IPBENCH2_KEEP_STATIC_LIBRARIES = YES

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
    $(IPBENCH2_CONF_ENV) && \
    mkdir -p $(STAGING_DIR)/ipbench && \
    ./configure \
        --build=$(GNU_HOST_NAME) \
        --host=$(GNU_TARGET_NAME) \
        --prefix=/ipbench/usr \
        --sysconfdir=/ipbench/etc \
        --localstatedir=/ipbench/var \
        --libdir=/ipbench/usr/lib \
        --disable-static \
        --enable-shared
        --with-sysroot=$(STAGING_DIR)
endef

# Fix libtool to handle cross-compilation
define IPBENCH2_POST_CONFIGURE_CMDS
    $(SED) "s,^CC=\"$$CC\",CC=\"$(TARGET_CC)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,^LD=\"$$LD\",LD=\"$(TARGET_LD)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,^NM=\"/usr/bin/nm -B\",NM=\"$(TARGET_NM)\"," $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,-L/usr/lib,,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) "s,\$${wl}-rpath \$${wl}/usr/lib,,g" $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) 's,^sys_lib_search_path_spec=.*,sys_lib_search_path_spec="$(STAGING_DIR)/usr/lib",' $(@D)/$(IPBENCH2_SUBDIR)/libtool
    $(SED) 's,^sys_lib_dlsearch_path_spec=.*,sys_lib_dlsearch_path_spec="$(STAGING_DIR)/usr/lib",' $(@D)/$(IPBENCH2_SUBDIR)/libtool
endef

define IPBENCH2_BUILD_CMDS
    mkdir -p $(TARGET_DIR)/usr/lib
    $(TARGET_MAKE_ENV) $(MAKE) \
        CC="$(TARGET_CC)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        LDFLAGS="$(TARGET_LDFLAGS)" \
        -C $(@D)/$(IPBENCH2_SUBDIR)
endef

define IPBENCH2_POST_INSTALL_STAGING_CMDS
    mkdir -p $(STAGING_DIR)/usr/bin
    ln -sf $(STAGING_DIR)/ipbench/usr/bin/ipbench $(STAGING_DIR)/usr/bin/ipbench
    ln -sf $(STAGING_DIR)/ipbench/usr/bin/ipbenchd $(STAGING_DIR)/usr/bin/ipbenchd

    mkdir -p $(STAGING_DIR)/usr/lib
    cd $(STAGING_DIR)/ipbench/usr/lib && \
    find . -type f -o -type l | while read file; do \
        mkdir -p $(STAGING_DIR)/usr/lib/$$(dirname $$file) && \
        ln -sf $(STAGING_DIR)/ipbench/usr/lib/$$file $(STAGING_DIR)/usr/lib/$$file ; \
    done
endef

IPBENCH2_POST_INSTALL_STAGING_HOOKS += IPBENCH2_POST_INSTALL_STAGING_CMDS

define IPBENCH2_INSTALL_TARGET_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        DESTDIR=$(TARGET_DIR) \
        -C $(@D)/$(IPBENCH2_SUBDIR) install
endef

define IPBENCH2_POST_INSTALL_TARGET_SYMLINK
    mkdir -p $(TARGET_DIR)/usr/bin
    ln -sf $(TARGET_DIR)/ipbench/usr/bin/ipbench $(TARGET_DIR)/usr/bin/ipbench
    ln -sf $(TARGET_DIR)/ipbench/usr/bin/ipbenchd $(TARGET_DIR)/usr/bin/ipbenchd
    mkdir -p $(TARGET_DIR)/usr/lib
    cd $(TARGET_DIR)/ipbench/usr/lib && \
    find . -type f -o -type l | while read file; do \
        mkdir -p $(TARGET_DIR)/usr/lib/$$(dirname $$file) && \
        ln -sf $(TARGET_DIR)/ipbench/usr/lib/$$file $(TARGET_DIR)/usr/lib/$$file ; \
    done
endef

IPBENCH2_POST_INSTALL_TARGET_HOOKS += IPBENCH2_POST_INSTALL_TARGET_CMDS
IPBENCH2_POST_INSTALL_TARGET_HOOKS += IPBENCH2_POST_INSTALL_TARGET_SYMLINK

define IPBENCH2_INSTALL_STAGING_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        DESTDIR=$(STAGING_DIR) \
        -C $(@D)/$(IPBENCH2_SUBDIR) install
endef

$(eval $(autotools-package))

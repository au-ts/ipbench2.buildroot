# ipbench2 for Buildroot

IPBENCH2_VERSION = 2.1.1
IPBENCH2_SITE = $(call github,au-ts,ipbench,crosscompilation)
IPBENCH2_SUBDIR = ipbench2
IPBENCH2_INSTALL_STAGING = YES
IPBENCH2_LICENSE = GPL-2.0
IPBENCH2_LICENSE_FILES = COPYING

IPBENCH2_DEPENDENCIES = host-swig host-python3 host-libtool python3

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

# The below step puts everything in an `/ipbench` subdirectory to avoid
# libtool freaking out about the staging directory being an unsafe location
# (detects usr, etc as the ones on your host!). These are moved out again in
# the POST_INSTALL_TARGET_CMDS.
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

# Move everything out of the dummy ipbench folder!
define IPBENCH2_POST_INSTALL_TARGET_CMDS
    @echo "Moving ipbench2 info to target directory"
    test -d $(TARGET_DIR)/ipbench/usr || (echo "Error: $(TARGET_DIR)/ipbench/usr does not exist" && exit 1)
    ls -la $(TARGET_DIR)/ipbench/usr
    mkdir -p $(TARGET_DIR)/usr
    cd $(TARGET_DIR)/ipbench/usr && \
        for d in ./*; do \
            if [ -d "$$d" ]; then \
                cp -rv "$$d" $(TARGET_DIR)/usr/ ; \
            else \
                cp -v "$$d" $(TARGET_DIR)/usr/ ; \
            fi \
        done
    @echo "Cleaning up temporary directory..."
    rm -rf $(TARGET_DIR)/ipbench
endef

IPBENCH2_POST_INSTALL_TARGET_HOOKS += IPBENCH2_POST_INSTALL_TARGET_CMDS

define IPBENCH2_INSTALL_STAGING_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) \
        DESTDIR=$(STAGING_DIR) \
        -C $(@D)/$(IPBENCH2_SUBDIR) install
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

$(eval $(autotools-package))


SOURCES = sources

COMPILER = gcc

GNU_SITE = https://ftpmirror.gnu.org/gnu
GCC_SITE = $(GNU_SITE)/gcc
BINUTILS_SITE = $(GNU_SITE)/binutils
GMP_SITE = $(GNU_SITE)/gmp
MPC_SITE = $(GNU_SITE)/mpc
MPFR_SITE = $(GNU_SITE)/mpfr
ISL_SITE = http://isl.gforge.inria.fr/
LLVM_SITE = https://github.com/llvm/llvm-project/releases/download

MUSL_SITE = https://musl.libc.org/releases
MUSL_REPO = git://git.musl-libc.org/musl

LINUX_SITE = https://cdn.kernel.org/pub/linux/kernel
LINUX_HEADERS_SITE = http://ftp.barfooze.de/pub/sabotage/tarballs/

DL_CMD = wget -c -O
SHA1_CMD = sha1sum -c

COWPATCH = $(CURDIR)/cowpatch.sh

HOST = $(if $(NATIVE),$(TARGET))
BUILD_DIR = build-$(COMPILER)/$(if $(HOST),$(HOST),local)/$(TARGET)
OUTPUT = $(CURDIR)/output$(if $(HOST),-$(HOST))

REL_TOP = ../..$(if $(TARGET),/..)

-include config.mak

MUSL_VER ?= 1.2.2
LINUX_VER ?= headers-4.19.88-1
CONFIG_SUB_REV ?= 3d5db9ebe860

ifeq ($(COMPILER),gcc)

BINUTILS_VER ?= 2.33.1
GCC_VER ?= 9.4.0
GMP_VER ?= 6.1.2
MPC_VER ?= 1.1.0
MPFR_VER ?= 4.0.2

endif

ifeq ($(COMPILER),clang)

LLVM_VER ?= 12.0.1

endif

SRC_DIRS = musl-$(MUSL_VER) \
	$(if $(GCC_VER),gcc-$(GCC_VER)) \
	$(if $(BINUTILS_VER),binutils-$(BINUTILS_VER)) \
	$(if $(GMP_VER),gmp-$(GMP_VER)) \
	$(if $(MPC_VER),mpc-$(MPC_VER)) \
	$(if $(MPFR_VER),mpfr-$(MPFR_VER)) \
	$(if $(ISL_VER),isl-$(ISL_VER)) \
	$(if $(LINUX_VER),linux-$(LINUX_VER)) \
	$(if $(LLVM_VER),llvm-project-$(LLVM_VER).src)

all:

clean:
	rm -rf gcc-* binutils-* musl-* gmp-* mpc-* mpfr-* isl-* build build-* linux-* llvm-project-*

distclean: clean
	rm -rf sources


# Rules for downloading and verifying sources. Treat an external SOURCES path as
# immutable and do not try to download anything into it.

ifeq ($(SOURCES),sources)

$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gmp*)): SITE = $(GMP_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpc*)): SITE = $(MPC_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpfr*)): SITE = $(MPFR_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/isl*)): SITE = $(ISL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils*)): SITE = $(BINUTILS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc*)): SITE = $(GCC_SITE)/$(basename $(basename $(notdir $@)))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/musl*)): SITE = $(MUSL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-5*)): SITE = $(LINUX_SITE)/v5.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-4*)): SITE = $(LINUX_SITE)/v4.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-3*)): SITE = $(LINUX_SITE)/v3.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-2.6*)): SITE = $(LINUX_SITE)/v2.6
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-headers-*)): SITE = $(LINUX_HEADERS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/llvm-project-*)): SITE = $(LLVM_SITE)/llvmorg-$(patsubst llvm-project-%.src,%,$(basename $(basename $(notdir $@))))

$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=$(CONFIG_SUB_REV)"
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHA1_CMD) $(CURDIR)/hashes/$(notdir $@).$(CONFIG_SUB_REV).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHA1_CMD) $(CURDIR)/hashes/$(notdir $@).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

endif


# Rules for extracting and patching sources, or checking them out from git.

musl-git-%:
	rm -rf $@.tmp
	git clone -b $(patsubst musl-git-%,%,$@) $(MUSL_REPO) $@.tmp
	cd $@.tmp && git fsck
	mv $@.tmp $@

%.orig: $(SOURCES)/%.tar.gz
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar zxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%.orig: $(SOURCES)/%.tar.bz2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%.orig: $(SOURCES)/%.tar.xz
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar Jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%: %.orig | $(SOURCES)/config.sub
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && $(COWPATCH) -I ../$< )
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp && $(COWPATCH) -p1 )
	if test -f $</configfsf.sub ; then cs=configfsf.sub ; elif test -f $</config.sub ; then cs=config.sub ; else exit 0 ; fi ; rm -f $@.tmp/$$cs && cp -f $(SOURCES)/config.sub $@.tmp/$$cs && chmod +x $@.tmp/$$cs
	rm -rf $@
	mv $@.tmp $@


# Add deps for all patched source dirs on their patchsets
$(foreach dir,$(notdir $(basename $(basename $(basename $(wildcard hashes/*))))),$(eval $(dir): $$(wildcard patches/$(dir) patches/$(dir)/*)))

extract_all: | $(SRC_DIRS)


# Rules for building.

ifeq ($(COMPILER)$(TARGET),gcc)

all:
	@echo TARGET must be set for gcc build via config.mak or command line.
	@exit 1

else

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Makefile: | $(BUILD_DIR)
	ln -sf $(REL_TOP)/litecross/Makefile.$(COMPILER) $@

$(BUILD_DIR)/config.mak: | $(BUILD_DIR)
	printf >$@ '%s\n' \
	$(if $(TARGET),"TARGET = $(TARGET)") \
	"HOST = $(HOST)" \
	"MUSL_SRCDIR = $(REL_TOP)/musl-$(MUSL_VER)" \
	$(if $(GCC_VER),"GCC_SRCDIR = $(REL_TOP)/gcc-$(GCC_VER)") \
	$(if $(BINUTILS_VER),"BINUTILS_SRCDIR = $(REL_TOP)/binutils-$(BINUTILS_VER)") \
	$(if $(GMP_VER),"GMP_SRCDIR = $(REL_TOP)/gmp-$(GMP_VER)") \
	$(if $(MPC_VER),"MPC_SRCDIR = $(REL_TOP)/mpc-$(MPC_VER)") \
	$(if $(MPFR_VER),"MPFR_SRCDIR = $(REL_TOP)/mpfr-$(MPFR_VER)") \
	$(if $(ISL_VER),"ISL_SRCDIR = $(REL_TOP)/isl-$(ISL_VER)") \
	$(if $(LINUX_VER),"LINUX_SRCDIR = $(REL_TOP)/linux-$(LINUX_VER)") \
	$(if $(LLVM_VER),"LLVM_SRCDIR = $(REL_TOP)/llvm-project-$(LLVM_VER).src") \
	$(if $(LLVM_VER),"LLVM_VER = $(LLVM_VER)") \
	"-include $(REL_TOP)/config.mak"

all: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) $@

install: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) OUTPUT=$(OUTPUT) $@

endif

.SECONDARY:

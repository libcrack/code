# vim: ft=make

comma := ,
empty :=
space := $(empty) $(empty)

UNAME    != uname
OBJ      != dist/prepare -o

ifeq ($(origin CC),default)
CC       := gcc
endif

CFLAGS   := -pipe -Wall -O1 -g
LDFLAGS  := -Wl,--as-needed

CRYPT_LDLIBS := -lcrypt
DL_LDLIBS    := -ldl
KRB_LDLIBS   := -lkrb5 -lcom_err

ifeq ($(UNAME),Linux)
	OSFLAGS := -DHAVE_LINUX
endif
ifeq ($(UNAME),FreeBSD)
	OSFLAGS := -DHAVE_FREEBSD
	DL_LDLIBS := $(empty)
endif
ifeq ($(UNAME),GNU)
	OSFLAGS := -DHAVE_HURD
endif
ifeq ($(UNAME),NetBSD)
	OSFLAGS := -DHAVE_NETBSD
endif
ifeq ($(UNAME),OpenBSD)
	OSFLAGS := -DHAVE_OPENBSD
	CRYPT_LDLIBS := $(empty)
	DL_LDLIBS    := $(empty)
	KRB_LDLIBS   := -lkrb5 -lcom_err -lcrypto
endif
ifeq ($(UNAME),CYGWIN_NT-5.1)
	OSFLAGS := -DHAVE_CYGWIN
endif
ifeq ($(UNAME),SunOS)
	OSFLAGS := -DHAVE_SOLARIS
	KRB_LDLIBS := -lkrb5
endif

override CFLAGS += -I./misc $(OSFLAGS) $(cflags)

ifeq ($(V),1)
	verbose_hide := $(empty)
	verbose_echo := @:
else
	verbose_hide := @
	verbose_echo := @echo
endif

# misc targets

.PHONY: default pre clean mrproper

default: pre
ifdef obj
default: $(addprefix $(OBJ)/,$(subst $(comma),$(space),$(obj)))
else
CURRENT_BINS := $(wildcard $(OBJ)/*)
ifneq ($(CURRENT_BINS),)
default: $(CURRENT_BINS)
else
default: basic
endif
endif

clean:
	rm -rf obj/arch.* obj/dist.* obj/host.*

mrproper:
	git clean -fdX
	git checkout -f obj

pre   := $(OBJ)/.prepare
dummy := dist/empty.c
arg    = $(firstword $(patsubst $(dummy),,$(1)))
args   = $(strip $(patsubst $(dummy),,$(1)))

pre:
	$(verbose_hide) dist/prepare

$(pre):
	$(verbose_hide) dist/prepare
	$(verbose_hide) touch $@

$(OBJ)/%.h: $(pre) dist/configure
	$(verbose_echo) "  GEN   $(notdir $@)"
	$(verbose_hide) dist/configure $@

$(dummy): $(pre)
$(dummy): $(OBJ)/config.h
$(dummy): $(OBJ)/config-krb5.h
	$(verbose_hide) touch $@

# compile recipes

$(OBJ)/%.o: $(dummy)
	$(verbose_echo) "  CC    $(notdir $@) ($(call arg,$^))"
	$(verbose_hide) $(COMPILE.c) $(OUTPUT_OPTION) $(call arg,$^)

$(OBJ)/%: $(dummy)
	$(verbose_echo) "  CCLD  $(notdir $@) ($(call args,$^))"
	$(verbose_hide) $(LINK.c) $(call args,$^) $(LOADLIBES) $(LDLIBS) -o $@

# compile targets

BASIC_BINS := args gettime mkpasswd natsort pause proctool silentcat spawn
BASIC_BINS += strtool unescape
KRB_BINS   := k5userok pklist
LINUX_BINS := globalenv libfunlink.so libfunsync.so showsigmask tapchown
MISC_BINS  := bgrep logwipe writevt xor xors xorf zlib
JUNK_BINS  := ac-wait subreaper libwcwidth.so

.PHONY: all basic krb linux misc pklist

basic: $(addprefix $(OBJ)/,$(BASIC_BINS))
krb:   $(addprefix $(OBJ)/,$(KRB_BINS))
linux: $(addprefix $(OBJ)/,$(LINUX_BINS))
misc:  $(addprefix $(OBJ)/,$(MISC_BINS))
junk:  $(addprefix $(OBJ)/,$(JUNK_BINS))

all: basic krb misc
ifeq ($(UNAME),Linux)
all: linux junk
endif

# advertised in the pklist readme
pklist: $(OBJ)/pklist

emergency-sulogin: $(OBJ)/emergency-sulogin
	sudo install -o 'root' -g 'wheel' -m 'u=rxs,g=rx,o=' $< /usr/bin/$@

# libraries

$(OBJ)/libfunlink.so:	CFLAGS += -shared -fPIC
$(OBJ)/libfunlink.so:	LDLIBS += $(DL_LDLIBS)
$(OBJ)/libfunlink.so:	system/libfunlink.c
$(OBJ)/libfunsync.so:	CFLAGS += -shared
$(OBJ)/libfunsync.so:	system/libfunsync.c
$(OBJ)/libwcwidth.so:	CFLAGS += -shared -fPIC \
				-Dmk_wcwidth=wcwidth -Dmk_wcswidth=wcswidth
$(OBJ)/libwcwidth.so:	thirdparty/wcwidth.c

# objects

$(OBJ)/misc_util.o:	misc/util.c misc/util.h
$(OBJ)/strnatcmp.o:	thirdparty/strnatcmp.c

# executables

$(OBJ)/ac-wait:		LDLIBS += -ludev
$(OBJ)/ac-wait:		system/ac-wait.c
$(OBJ)/args:		misc/args.c
$(OBJ)/bgrep:		thirdparty/bgrep.c
$(OBJ)/gettime:		misc/gettime.c
$(OBJ)/codeset:		misc/codeset.c
$(OBJ)/entropy:		LDLIBS += -lm
$(OBJ)/entropy:		security/entropy.c
$(OBJ)/globalenv:	LDLIBS += -lkeyutils
$(OBJ)/globalenv:	system/globalenv.c $(OBJ)/misc_util.o
$(OBJ)/k5userok:	LDLIBS += $(KRB_LDLIBS)
$(OBJ)/k5userok:	kerberos/k5userok.c
$(OBJ)/logwipe:		thirdparty/logwipe.c
$(OBJ)/mkpasswd:	LDLIBS += $(CRYPT_LDLIBS)
$(OBJ)/mkpasswd:	security/mkpasswd.c
$(OBJ)/natsort:		thirdparty/natsort.c $(OBJ)/strnatcmp.o
$(OBJ)/pklist:		LDLIBS += $(KRB_LDLIBS)
$(OBJ)/pklist:		kerberos/pklist.c
$(OBJ)/pause:		system/pause.c
$(OBJ)/proctool:	system/proctool.c $(OBJ)/misc_util.o
$(OBJ)/showsigmask:	system/showsigmask.c
$(OBJ)/silentcat:	misc/silentcat.c
$(OBJ)/spawn:		system/spawn.c $(OBJ)/misc_util.o
$(OBJ)/strtool:		misc/strtool.c $(OBJ)/misc_util.o
$(OBJ)/subreaper:	system/subreaper.c
$(OBJ)/tapchown:	net/tapchown.c
$(OBJ)/unescape:	misc/unescape.c
$(OBJ)/writevt:		thirdparty/writevt.c
$(OBJ)/xor:		misc/xor.c
$(OBJ)/xorf:		misc/xorf.c
$(OBJ)/xors:		misc/xors.c
$(OBJ)/zlib:		LDLIBS += -lz
$(OBJ)/zlib:		thirdparty/zpipe.c

$(OBJ)/emergency-sulogin:	LDLIBS += $(CRYPT_LDLIBS) -static
$(OBJ)/emergency-sulogin:	security/emergency-sulogin.c

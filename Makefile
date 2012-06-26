#!make

UNAME := $(shell uname)
HOSTNAME := $(shell hostname)
#MACHTYPE := $(shell cc -dumpmachine)
MACHTYPE := $(shell bash -c 'echo $$MACHTYPE')

ARCHOBJ := obj/arch.$(MACHTYPE)
HOSTOBJ := obj/host.$(HOSTNAME)
OBJ := $(HOSTOBJ)

CC = gcc
CFLAGS = -Wall -O2 $(OSFLAGS)

ifeq ($(UNAME),Linux)
	OSFLAGS := -DHAVE_LINUX
else ifeq ($(UNAME),FreeBSD)
	OSFLAGS := -DHAVE_FREEBSD
else ifeq ($(UNAME),NetBSD)
	OSFLAGS := -DHAVE_NETBSD
else ifeq ($(UNAME),CYGWIN_NT-5.1)
	OSFLAGS := -DHAVE_CYGWIN
endif

# misc targets

.PHONY: pre all clean

DEFAULT: all

pre:
	@dist/prepare

clean:
	rm -rf $(ARCHOBJ) $(HOSTOBJ)

mrproper:
	git clean -dfX

# compile targets

BASIC_BINS := args silentcat spawn
KRB_BINS := k5userok pklist
LINUX_BINS := linux26 tapchown
MISC_BINS := bgrep logwipe natsort writevt xor xors

cc-basic: $(addprefix $(OBJ)/,$(BASIC_BINS))
cc-krb: $(addprefix $(OBJ)/,$(KRB_BINS))
cc-linux: $(addprefix $(OBJ)/,$(LINUX_BINS))
cc-misc: $(addprefix $(OBJ)/,$(MISC_BINS))

cc-all: cc-basic cc-krb cc-misc
ifeq ($(UNAME),Linux)
cc-all: cc-linux
endif

all: cc-all

$(addprefix $(OBJ)/,$(KRB_BINS)): LDLIBS := -lkrb5 -lcom_err

$(OBJ)/args:		misc/args.c
$(OBJ)/bgrep:		thirdparty/bgrep.c
$(OBJ)/k5userok:	kerberos/k5userok.c kerberos/krb5.h
$(OBJ)/linux26:		thirdparty/linux26.c
$(OBJ)/logwipe:		thirdparty/logwipe.c
$(OBJ)/natsort:		thirdparty/natsort.c thirdparty/strnatcmp.c
$(OBJ)/pklist:		kerberos/pklist.c kerberos/krb5.h
$(OBJ)/silentcat:	misc/silentcat.c
$(OBJ)/spawn:		misc/spawn.c
$(OBJ)/tapchown:	net/tapchown.c
$(OBJ)/writevt:		thirdparty/writevt.c
$(OBJ)/xor:		misc/xor.c
$(OBJ)/xors:		misc/xors.c

$(OBJ)/%: | pre
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

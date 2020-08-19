#!/usr/bin/xcrun make

PREFIX?=/usr/local

CARTHAGE_CACHE_EXECUTABLE=./.build/release/carthage_cache
BINARIES_FOLDER=/usr/local/bin

SWIFT_BUILD_FLAGS=--configuration release -Xswiftc -suppress-warnings

SWIFT_STATIC_STDLIB_SHOULD_BE_FLAGGED:=$(shell test -d $$(dirname $$(xcrun --find swift))/../lib/swift_static/macosx && echo should_be_flagged)
ifeq ($(SWIFT_STATIC_STDLIB_SHOULD_BE_FLAGGED), should_be_flagged)
SWIFT_BUILD_FLAGS+= -Xswiftc -static-stdlib
endif

VERSION_STRING=$(shell git describe --abbrev=0 --tags)

RM=rm -f
MKDIR=mkdir -p
SUDO=sudo
CP=cp

all: installables

clean:
	swift package clean

installables:
	swift build $(SWIFT_BUILD_FLAGS)

install: installables
	if [ ! -d "$(BINARIES_FOLDER)" ]; then $(SUDO) $(MKDIR) "$(BINARIES_FOLDER)"; fi
	$(SUDO) $(CP) -f "$(CARTHAGE_CACHE_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	$(RM) "$(BINARIES_FOLDER)/carthage_cache"
	
xcodeproj:
	 swift package generate-xcodeproj
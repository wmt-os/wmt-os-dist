#!/bin/bash
# Build the imlib2 armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb imlib2 <<-'EOF'
	patch -p1 < /input/01-enable-packing.patch

	dch -v "$WMTOS_VERSION" -D trixie \
		"Fix PNG unaligned access SIGSEGV on armel via --enable-packing."
	EOF

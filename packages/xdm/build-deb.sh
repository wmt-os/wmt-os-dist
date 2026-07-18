#!/bin/bash
# Build the xdm armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb xdm <<-'EOF'
	mv /input/wmt-os*.xpm debian/local/
	patch -p1 < /input/01-wmt-os-pixmaps.patch

	# Source patches must join the series or the clean target's unapply breaks
	cp /input/02-fail-clear-width.patch debian/patches/
	echo 02-fail-clear-width.patch >> debian/patches/series

	dch -v "$WMTOS_VERSION" -D trixie \
		"Default the login logo to WMT OS."
	dch -a "Fix the greeter erasing the frame bevel."
	EOF

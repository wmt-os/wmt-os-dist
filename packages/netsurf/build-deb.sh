#!/bin/bash
# Build the netsurf armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb netsurf <<-'EOF'
	patch -p1 < /input/01-gtk2.patch
	patch -p1 < /input/02-x-www-browser.patch

	dch -v "$WMTOS_VERSION" -D trixie \
		"Build the GTK frontend against GTK 2."
	dch -a "Register an x-www-browser alternative with matching pixmaps."
	EOF

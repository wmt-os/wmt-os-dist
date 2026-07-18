#!/bin/bash
# Build the gogglesmm armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb gogglesmm <<-'EOF'
	patch -p1 < /input/01-scroll-blank.patch
	patch -p1 < /input/02-playing-defaults.patch

	dch -v "$WMTOS_VERSION" -D trixie \
		"Blank freshly exposed strips when scrolling to stop duplication."
	dch -a "Disable the playing view's cover art and lyrics by default."
	EOF

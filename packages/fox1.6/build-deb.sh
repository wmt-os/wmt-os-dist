#!/bin/bash
# Build the fox1.6 armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb fox1.6 <<-'EOF'
	patch -p1 < /input/01-scroll-blank.patch
	patch -p1 < /input/02-wheel-timing.patch
	patch -p1 < /input/03-selection-repaint.patch
	patch -p1 < /input/04-typing-damage.patch
	patch -p1 < /input/05-utils-package.patch
	patch -p1 < /input/06-format-security.patch
	patch -p1 < /input/07-adie-highlighting.patch

	# Reuse each application's window icon as its desktop entry icon
	apt-get -y --no-install-recommends install imagemagick
	magick adie/big_gif.gif debian/adie.xpm
	magick calculator/bigcalc.gif debian/calculator.xpm
	magick shutterbug/shutterbug.gif debian/shutterbug.xpm

	dch -v "$WMTOS_VERSION" -D trixie \
		"Blank freshly exposed strips when scrolling to stop duplication."
	dch -a "Backport the 1.7 wheel timing so painting keeps pace with the glide."
	dch -a "Repaint the selection as it changes to keep highlighting current."
	dch -a "Repaint only from the change onward when editing a line."
	dch -a "Ship the bundled applications as fox1.6-utils with desktop entries."
	dch -a "Do not treat format-security as an error in the applications."
	dch -a "Ship Adie's syntax file and default colors for highlighting."
	EOF

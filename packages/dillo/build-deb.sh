#!/bin/bash
# Build the dillo armel deb packages
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

build_deb dillo sid <<-'EOF'
	dch -b -v "$WMTOS_VERSION" -D trixie \
		"Backport the sid source for trixie."
	EOF

#!/bin/bash
# Build the gogglesmm armel deb package
#
# Output: ./dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../lib.sh"

WMTOS_REV=1

mkdir -p "$OUT"
rm -f "$OUT"/*.deb
mmdebstrap --variant=buildd --architectures=armel --include="devscripts" \
	--customize-hook="copy-in $SRC/patches /" \
	--chrooted-customize-hook="$(cat <<-EOF
		set -e

		apt-get source gogglesmm
		cd gogglesmm-*
		patch -p1 < /patches/01-scroll-blank.patch
		patch -p1 < /patches/02-playing-defaults.patch

		export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"
		dch -v "\$(dpkg-parsechangelog -S Version)+wmtos$WMTOS_REV" -D trixie \
			"Blank freshly exposed strips when scrolling to stop duplication."
		dch -a "Disable the playing view's cover art and lyrics by default."

		apt-get -y --no-install-recommends build-dep ./
		dpkg-buildpackage -b -uc -us -j$(nproc)

		mkdir /out
		mv /*.deb /out/
		EOF
	)" \
	--customize-hook="sync-out /out $OUT" \
	trixie /dev/null "$SRC"/../debian.sources

ls -1 "$OUT"/*.deb

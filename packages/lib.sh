#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
OUT=${OUT:-$SRC/dist}
. "$BASE_DIR/config.sh"

renice "$NICE" -p $$ >/dev/null 2>&1 || true

build_deb() {
	local recipe; recipe=$(cat)
	mkdir -p "$OUT"
	rm -f "$OUT"/*.deb
	mmdebstrap --variant=buildd --architectures=armel --include=devscripts \
		--customize-hook="copy-in $SRC/input /" \
		--chrooted-customize-hook="$(cat <<-EOF
			set -e

			apt-get source $1
			cd $1-*

			export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"
			sed -i "s/^Maintainer:/Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>\nXSBC-Original-Maintainer:/" debian/control
			sed -i "s/^Uploaders:/XSBC-Original-Uploaders:/" debian/control
			v=\$(dpkg-parsechangelog -S Version); base=\${v%%+deb[0-9]*}
			WMTOS_VERSION=\$base+wmtos$WMTOS_REV\${v#\$base}

			$recipe

			apt-get -y --no-install-recommends build-dep ./
			dpkg-buildpackage -b -uc -us -j$(nproc)

			mkdir /out
			mv /*.deb /out/
			EOF
		)" \
		--customize-hook="sync-out /out $OUT" \
		trixie /dev/null "$SRC/../debian.sources"

	ls -1 "$OUT"/*.deb
}

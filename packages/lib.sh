#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
OUT=${OUT:-$SRC/dist}
. "$BASE_DIR/config.sh"

renice "$NICE" -p $$ >/dev/null 2>&1 || true

build_deb() {
	local recipe; recipe=$(cat)
	local version='$base+wmtos'$WMTOS_REV'${v#$base}' hooks=()
	[ $# -gt 1 ] && version='$v~wmtos'$WMTOS_REV # Backport if suite is defined
	[ -d "$SRC/input" ] && hooks=(--customize-hook="copy-in $SRC/input /")

	mkdir -p "$OUT"
	rm -f "$OUT"/*.deb
	mmdebstrap --variant=buildd --architectures=armel --include=devscripts \
		"${hooks[@]}" \
		--chrooted-customize-hook="$(cat <<-EOF
			set -e

			apt-get source $1${2:+/$2}
			cd $1-*

			export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"
			sed -i "s/^Maintainer:/Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>\nXSBC-Original-Maintainer:/" debian/control
			sed -i "s/^Uploaders:/XSBC-Original-Uploaders:/" debian/control
			v=\$(dpkg-parsechangelog -S Version); base=\${v%%+deb[0-9]*}
			WMTOS_VERSION=$version

			$recipe

			apt-get -y --no-install-recommends build-dep ./
			dpkg-buildpackage -b -uc -us -j$(nproc)

			mkdir /out
			mv /*.deb /out/
			EOF
		)" \
		--customize-hook="sync-out /out $OUT" \
		trixie /dev/null "$SRC/../debian.sources" ${2:+"$SRC/../$2.sources"}

	ls -1 "$OUT"/*.deb
}

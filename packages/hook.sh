#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"

if [ ! -d "/$PKG/debian" ]; then
	apt-get source "$PKG${SUITE:+/$SUITE}"
	cd "$PKG"-*

	sed -i "s/^Maintainer:/Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>\nXSBC-Original-Maintainer:/" debian/control
	sed -i "s/^Uploaders:/XSBC-Original-Uploaders:/" debian/control

	v=$(dpkg-parsechangelog -S Version)
	base=${v%%+deb[0-9]*}
	ver="$base+wmtos$REV${v#$base}"
	[ -n "$SUITE" ] && ver="$v~wmtos$REV"

	patches=(/"$PKG"/*.patch)
	d=()
	if [ -e "${patches[0]}" ]; then
		mkdir -p debian/patches
		cp "${patches[@]}" debian/patches/
		printf '%s\n' "${patches[@]##*/}" >> debian/patches/series
		QUILT_PATCHES=debian/patches quilt push -a
		mapfile -t d < <(sed -n "s/^Description: //p" "${patches[@]}")
	fi

	[ -n "$SUITE" ] && d=("Backport from $SUITE" "${d[@]}")
	dch -b -v "$ver" -D "$TARGET" "${d[0]:-}"
	for m in "${d[@]:1}"; do dch --noquery -a "$m"; done
	flags=-nc # Pre-clean unpatches, and make parses debian/rules before repush
else
	cp -r "/$PKG/debian" /src/
	cd /src
	flags=-b # No orig tarball to build a source package from
fi

eval "$RECIPE"
apt-get -y --no-install-recommends build-dep ./
dpkg-buildpackage -uc -us "$flags" -j$(nproc)

mkdir /out
mv /*.deb /out/

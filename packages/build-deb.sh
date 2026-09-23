#!/bin/bash
# Build an external armel package
#
# Usage:
#   ./build-deb.sh PACKAGE    # Package name under packages/
#
# Output: packages/<name>/dist/*.deb (override: OUT=)
# Requires: curl dpkg-dev mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu

die() { echo "build-deb: $*" >&2; exit 1; }

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$BASE_DIR/config.sh"

renice "$NICE" -p $$ >/dev/null 2>&1 || true

[ $# -eq 1 ] || die "usage: build-deb PACKAGE"

export PKG=${1%/} REV= SUITE= RECIPE=
SRC=$BASE_DIR/packages/$PKG tree=

[ -f "$SRC/conf" ] || die "missing recipe"

if [ ! -d "$SRC/debian" ]; then
	. "$SRC/conf"
	[ -n "$REV" ] || die "missing revision"
else
	VER=$(dpkg-parsechangelog -l "$SRC/debian/changelog" -S Version)
	VER=${VER%-*} # Upstream version, for the conf URL
	. "$SRC/conf"
	tree=${TREE:-}
	if [ -z "$tree" ]; then
		tree=$(mktemp -d)
		trap 'rm -rf "$tree"' EXIT
		curl -fsSL "$URL" | tar -xz -C "$tree" --strip-components=1
	fi
fi

OUT=${OUT:-$SRC/dist}
mkdir -p "$OUT"
rm -f "$OUT"/*.deb

mmdebstrap --variant=buildd --architectures=armel --include="devscripts,quilt${INCLUDE:+,$INCLUDE}" \
	${SUITE:+--setup-hook="copy-in $BASE_DIR/packages/$SUITE.pref /etc/apt/preferences.d"} \
	${tree:+--customize-hook='mkdir "$1/src"' --customize-hook="sync-in $tree /src"} \
	--customize-hook="copy-in $BASE_DIR/packages/hook.sh $SRC /" \
	--chrooted-customize-hook='bash /hook.sh' \
	--customize-hook="sync-out /out $OUT" \
	"$TARGET" /dev/null "$BASE_DIR/packages/debian.sources" ${SUITE:+"$BASE_DIR/packages/$SUITE.sources"}

ls -1 "$OUT"/*.deb

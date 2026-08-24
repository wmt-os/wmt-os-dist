#!/bin/bash
# Build an external Debian-derived armel package
#
# Usage:
#   ./build-deb.sh PACKAGE    # Package name under packages/
#
# Output: packages/<name>/dist/*.deb (override: OUT=)
# Requires: mmdebstrap qemu-user-binfmt uidmap
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu

die() { echo "build-deb: $*" >&2; exit 1; }

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
. "$BASE_DIR/config.sh"

renice "$NICE" -p $$ >/dev/null 2>&1 || true

[ $# -eq 1 ] || die "usage: build-deb PACKAGE"

export PKG=${1%/} REV= SUITE= RECIPE=
SRC=$BASE_DIR/packages/$PKG

[ -f "$SRC/conf" ] || die "missing recipe"
. "$SRC/conf"
[ -n "$REV" ] || die "missing revision"

OUT=${OUT:-$SRC/dist}
mkdir -p "$OUT"
rm -f "$OUT"/*.deb

mmdebstrap --variant=buildd --architectures=armel --include="devscripts,quilt${INCLUDE:+,$INCLUDE}" \
	${SUITE:+--setup-hook="copy-in $BASE_DIR/packages/$SUITE.pref /etc/apt/preferences.d"} \
	--customize-hook="copy-in $BASE_DIR/packages/hook.sh $SRC /" \
	--chrooted-customize-hook='bash /hook.sh' \
	--customize-hook="sync-out /out $OUT" \
	"$TARGET" /dev/null "$BASE_DIR/packages/debian.sources" ${SUITE:+"$BASE_DIR/packages/$SUITE.sources"}

ls -1 "$OUT"/*.deb

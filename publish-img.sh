#!/bin/bash
# WMT OS Image Publisher
#
# Publish disk images to the release site: list remote, validate, upload, relink latest
#
# Usage:
#   ./publish-img.sh path/to/*.img.xz    # Validate and publish (including .sha256)
#   ./publish-img.sh                     # Relink latest (non-destructive / initialize empty)
#
# Requires: rsync
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
export LC_ALL=C

SRC=$(cd "$(dirname "$0")" && pwd)
. "$SRC/config.sh"

LATEST="$(mktemp -d)/latest"
trap 'rm -rf "${LATEST%/*}"' EXIT
mkdir "$LATEST"

imgname() { [[ $1 =~ ^[^[:space:]]+-[0-9]{8}_[0-9]{6}(\.img\.[a-z0-9]+)$ ]]; }

exec 9<"$0"; flock 9

# List published images from the remote (authoritative)
if ! list=$(rsync --list-only "$RELEASES/" 2>/dev/null); then
	if [[ $RELEASES == *:* ]] || [ -e "$RELEASES" ]; then
		echo "publish-img: cannot list $RELEASES" >&2; exit 1
	fi
	list=
fi
published=()
for w in $list; do
	imgname "$w" || continue
	published+=("$w")
done

# Validate all images and their build-time checksums; abort before touching the site on error
err=
for img in "$@"; do
	name=${img##*/}
	if ! imgname "$name"; then
		echo "error: unrecognized name: $name" >&2; err=1; continue
	fi
	if [ ! -r "$img" ]; then
		echo "error: unreadable: $img" >&2; err=1; continue
	fi
	{ read -r _ wname < "$img.sha256"; } 2>/dev/null || wname=
	if [ "$wname" != "$name" ]; then
		echo "error: bad or missing checksum: $name.sha256" >&2; err=1
	fi
done
[ -z "$err" ] || { echo "publish-img: refused (site untouched)" >&2; exit 1; }

# Link latest at the newest image per stem (the name with its datestamp stripped)
names=$(printf '%s\n' "${published[@]-}" "${@##*/}" | sort -u)
declare -A newest
for n in $names; do
	newest[${n%-*}]=$n
done

for p in "${!newest[@]}"; do
	imgname "${newest[$p]}" # recapture the suffix
	ln -s "../${newest[$p]}" "$LATEST/$p${BASH_REMATCH[1]}"
done

# Queue uploads with their checksums; a republished name must match the published content
upload=() err=
for img in "$@"; do
	name=${img##*/}
	if [[ " ${published[*]-} " != *" $name "* ]]; then
		echo "publish: $name"; upload+=("$img"*)
		continue
	fi
	differs=$(rsync -nc --out-format=%n "$img" "$RELEASES/") ||
		{ echo "publish-img: cannot compare with $RELEASES" >&2; exit 1; }
	if [ -z "$differs" ]; then
		echo "skip: $name already published"
	else
		echo "error: $name differs from published" >&2; err=1
	fi
done
[ -z "$err" ] || { echo "publish-img: refused (site untouched)" >&2; exit 1; }

# Push: images first so latest never dangles, then the link swap
case $RELEASES in *:*) ;; *) mkdir -p "$RELEASES" ;; esac
if [ ${#upload[@]} -gt 0 ]; then
	rsync -a "${upload[@]}" "$RELEASES/"
fi
rsync -a --delete "$LATEST/" "$RELEASES/latest/"
echo "publish-img: site updated at $RELEASES"

#!/bin/bash
# WMT OS Package Checker
#
# Compare published Debian-derived packages against Debian's current versions
#
# Usage:
#   ./check-deb.sh              # Table: SOURCE WMT-OS DEBIAN RECIPE STATUS
#   ./check-deb.sh | ansi2txt   # Plain text
#
# Requires: curl dpkg devscripts dctrl-tools bsdextrautils colorized-logs
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
export LC_ALL=C
shopt -s extglob

SRC=$(cd "$(dirname "$0")" && pwd)
. "$SRC/config.sh"
INDEX="${INDEX:-https://apt.wmt-os.org/dists/$TARGET/main/binary-armel/Packages}"

die() { echo "check-deb: $*" >&2; exit 1; }

# Terminal colors for status output
{ red=$(tput setaf 1) green=$(tput setaf 2) yellow=$(tput setaf 3) off=$(tput sgr0); } 2>/dev/null || :

# Published package versions from repository index
index=$(curl -fsSm30 "$INDEX") || die "cannot fetch $INDEX"
[[ $index == *Package:* ]] || die "$INDEX is not a Packages index"
declare -A pub=()
while IFS='|' read -r _ s p v _; do
	v=${v// /}
	[[ $v == *[+~]wmtos* ]] || continue
	s=${s%%(*} s=${s// /} s=${s:-${p// /}} # Source field, fallback to Package
	if [ -z "${pub[$s]:-}" ] || dpkg --compare-versions "$v" gt "${pub[$s]}"; then
		pub[$s]=$v
	fi
done < <(tbl-dctrl -c Source -c Package -c Version <<<"$index")
[ ${#pub[@]} -gt 0 ] || die "no wmt-os packages in index"

# Package recipes on disk, with the suite each builds from
declare -A rec=()
for f in "$SRC"/packages/*/conf; do
	[ -e "$f" ] || break
	SUITE=
	. "$f"
	f=${f%/conf}; rec[${f##*/}]=${SUITE:-$TARGET}
done

# Current Debian versions from rmadison, kept per suite
srcs=$(printf '%s\n' "${!pub[@]}" "${!rec[@]}" | sort -u)
suites=$(printf '%s\n' "$TARGET" "$TARGET-updates" "$TARGET-security" "${rec[@]}" | sort -u | paste -sd,)
declare -A deb=()
while IFS='|' read -r s v u _; do
	s=${s// /} v=${v// /} u=${u// /} u=${u/#$TARGET-*/$TARGET} # Pockets are the release reference
	[[ $v =~ ^[0-9][0-9A-Za-z.:~+-]*$ ]] || continue
	if [ -z "${deb[$u/$s]:-}" ] || dpkg --compare-versions "$v" gt "${deb[$u/$s]}"; then
		deb[$u/$s]=$v
	fi
done < <(rmadison -u qa -a source -s "$suites" $srcs)
[ ${#deb[@]} -gt 0 ] || die "madison returned nothing"

{
	printf 'SOURCE\tWMT-OS\tDEBIAN\tRECIPE\tSTATUS\n'
	for s in $srcs; do
		o=${pub[$s]:-} d=${deb[${rec[$s]:-$TARGET}/$s]:-} r=yes
		[ -n "${rec[$s]:-}" ] || r=no
		base=${o/[+~]wmtos+([0-9])/} # Strip wmtos revision suffix
		if [ -z "$o" ]; then
			st=$yellow'UNPUBLISHED'$off
		elif [ -z "$d" ]; then
			st=$yellow'NOT IN DEBIAN'$off
		elif [ "$r" = no ]; then
			st=$red'NO RECIPE'$off
		elif dpkg --compare-versions "$base" eq "$d"; then
			st=$green'OK'$off
		elif dpkg --compare-versions "$base" lt "$d"; then
			st=$red'NEEDS UPDATE'$off
		else
			st=$yellow'AHEAD'$off
		fi
		printf '%s\t%s\t%s\t%s\t%s\n' "$s" "${o:--}" "${d:--}" "$r" "$st"
	done
} | column -t -s$'\t'

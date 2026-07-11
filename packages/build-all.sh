#!/bin/bash
# Build every package recipe
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu

for recipe in "$(dirname "$0")"/*/build-deb.sh; do
	echo "==> $(basename "$(dirname "$recipe")")"
	"$recipe"
done

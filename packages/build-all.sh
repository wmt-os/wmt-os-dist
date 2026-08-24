#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu

cd "$(dirname "$0")"

for pkg in */conf; do
	echo "==> ${pkg%/conf}"
	./build-deb.sh "${pkg%/conf}"
done

#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Oliver Mesieh
# build.sh — rebuild lgpl/lib/'s archives from the source in lgpl/src/.
#
#     lgpl/build.sh [OUTDIR]          (default: lgpl/lib, in place)
#
# Compiles every member with the image's own flags (lgpl/compile/) and archives
# them in the original order: unchanged source gives back the same archives
# byte for byte.
#
# Needs the same packages as ../relink.sh, found the same way (see there).
set -euo pipefail

LGPL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
KIT="$(dirname "$LGPL")"
OUT="${1:-$LGPL/lib}"
PKG="${PLATFORMIO_PACKAGES_DIR:-$HOME/.platformio/packages}"

find_package() {
    local d
    for d in "$PKG/$1" "$PKG/$1"@*; do
        [ -f "$d/package.json" ] || continue
        if grep -q "\"version\": *\"$2\"" "$d/package.json"; then echo "$d"; return; fi
    done
    echo "${0##*/}: $1 $2 not found in $PKG — install it, or set the *_DIR variable" >&2
    exit 1
}
want() { sed -n "s/^$1 //p" "$KIT/link/packages.txt"; }
FRAMEWORK_DIR="${FRAMEWORK_DIR:-$(find_package framework-arduinoespressif32 "$(want framework-arduinoespressif32)")}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$(find_package toolchain-xtensa-esp32s3 "$(want toolchain-xtensa-esp32s3)")}"
# Physical paths: the compiler records them, and the prefix maps below must
# match what it records.
FRAMEWORK_DIR="$(cd "$FRAMEWORK_DIR" && pwd -P)"
TOOLCHAIN_DIR="$(cd "$TOOLCHAIN_DIR" && pwd -P)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd -P)"

# The arguments with this machine's paths filled in, into SUBST.
subst() {
    SUBST=("${@//@FRAMEWORK_DIR@/$FRAMEWORK_DIR}")
    SUBST=("${SUBST[@]//@TOOLCHAIN_DIR@/$TOOLCHAIN_DIR}")
    SUBST=("${SUBST[@]//@KIT@/$KIT}")
}

# Map every path the compiler records to the neutral name the published
# objects carry.
MAPS=()
while IFS= read -r m; do MAPS+=("-ffile-prefix-map=$m"); done < "$LGPL/compile/maps.txt"
subst "${MAPS[@]}"
MAPS=("${SUBST[@]}")

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$KIT"
while IFS= read -r archive; do
    mkdir -p "$WORK/$archive"
    MEMBERS=()
    while IFS=$'\t' read -r member compiler source; do
        FLAGS=()
        while IFS= read -r f; do FLAGS+=("$f"); done < "$LGPL/compile/$archive.$compiler.flags"
        subst "${FLAGS[@]}"
        "$TOOLCHAIN_DIR/bin/$compiler" -o "$WORK/$archive/$member" -c "${SUBST[@]}" "${MAPS[@]}" "$source"
        MEMBERS+=("$member")
    done < "$LGPL/compile/$archive.list"
    rm -f "$OUT/$archive"
    (cd "$WORK/$archive" && "$TOOLCHAIN_DIR/bin/xtensa-esp32s3-elf-ar" rcsD "$OUT/$archive" "${MEMBERS[@]}")
    echo "$archive: ${#MEMBERS[@]} objects"
done < "$LGPL/compile/archives.txt"

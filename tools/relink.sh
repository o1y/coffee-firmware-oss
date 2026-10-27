#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Oliver Mesieh
# relink.sh — link this kit into the firmware image.
#
#     ./relink.sh [OUTDIR]          (default: ./out)
#
# Writes OUTDIR/firmware.{elf,map,bin} and compares the .bin with SHA256SUMS:
# an unchanged kit gives back the published image byte for byte.
#
# Finds the PlatformIO packages link/packages.txt names in
# $PLATFORMIO_PACKAGES_DIR (default ~/.platformio/packages); FRAMEWORK_DIR,
# TOOLCHAIN_DIR or ESPTOOL_DIR override one. PYTHON runs esptool, which needs
# pyserial (default: PlatformIO's interpreter, else python3).
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$KIT/out}"
PKG="${PLATFORMIO_PACKAGES_DIR:-$HOME/.platformio/packages}"
PENV_PYTHON="$HOME/.platformio/penv/bin/python"
[ -x "$PENV_PYTHON" ] || PENV_PYTHON=python3
PYTHON="${PYTHON:-$PENV_PYTHON}"

# link/FILE's non-empty lines into LINES_OUT (bash 3.2 has no mapfile).
lines() { LINES_OUT=(); while IFS= read -r l; do [ -n "$l" ] && LINES_OUT+=("$l"); done < "$KIT/link/$1"; }

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
ESPTOOL_DIR="${ESPTOOL_DIR:-$(find_package tool-esptoolpy "$(want tool-esptoolpy)")}"

lines objects.txt;        OBJECTS=("${LINES_OUT[@]}")
lines archives.txt;       ARCHIVES=("${LINES_OUT[@]}")
lines framework-libs.txt; LIBS=("${LINES_OUT[@]}")
lines linkflags.txt;      LINKFLAGS=("${LINES_OUT[@]}")
lines elf2image.txt;      ELF2IMAGE=("${LINES_OUT[@]}")
lines libpath.txt;        LIBPATH=()
for d in "${LINES_OUT[@]}"; do LIBPATH+=(-L "$FRAMEWORK_DIR/$d"); done

mkdir -p "$OUT"
cd "$KIT"
# The project's archives and the framework's libraries share ONE group, in this
# order, the libraries as -l flags exactly as the framework's build script lists
# them: that is the command line the image was linked with.
"$TOOLCHAIN_DIR/bin/xtensa-esp32s3-elf-g++" -o "$OUT/firmware.elf" "${LINKFLAGS[@]}" \
    "-Wl,-Map=$OUT/firmware.map" "${OBJECTS[@]}" "${LIBPATH[@]}" \
    -Wl,--start-group "${ARCHIVES[@]}" "${LIBS[@]}" -Wl,--end-group
"$PYTHON" "$ESPTOOL_DIR/esptool.py" "${ELF2IMAGE[@]}" -o "$OUT/firmware.bin" "$OUT/firmware.elf" \
    > "$OUT/elf2image.log"

got="$("$PYTHON" -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$OUT/firmware.bin")"
echo "firmware.bin  $got"
if [ -f "$KIT/SHA256SUMS" ]; then
    if grep -q "^$got  firmware.bin$" "$KIT/SHA256SUMS"; then
        echo "identical to the published image"
    else
        echo "differs from the published image (expected if a library was changed)"
    fi
fi

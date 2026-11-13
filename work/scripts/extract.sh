#!/bin/bash
set -u
SRC="$HOME/gpm/out"
DST="/mnt/e/Dennis/GamePadDex复刻/work/decompile"
rm -rf "$DST"; mkdir -p "$DST"
cp -r "$SRC/sources/com/pkyul13" "$DST/pkyul13_sources" 2>/dev/null
cp -r "$SRC/resources/res" "$DST/res" 2>/dev/null
cp -r "$SRC/resources/assets" "$DST/assets" 2>/dev/null
cp "$SRC/resources/AndroidManifest.xml" "$DST/AndroidManifest.xml" 2>/dev/null
cp -r "$SRC/resources/kotlin" "$DST/kotlin_meta" 2>/dev/null
echo "=== app source tree ==="
find "$DST/pkyul13_sources" -name '*.java' | sed "s|$DST/pkyul13_sources/||" | sort
echo
echo "=== counts ==="
find "$DST/pkyul13_sources" -name '*.java' | wc -l
find "$DST" -maxdepth 1 -mindepth 1 | sed "s|$DST/||"

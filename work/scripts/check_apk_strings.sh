#!/usr/bin/env bash
set -e
APK="$1"
TMP=$(mktemp -d)
cd "$TMP"
unzip -o -q "$APK" -d apk
for f in apk/classes*.dex; do
  echo "$f: $(strings "$f" | grep -c force_phone) force_phone, $(strings "$f" | grep -c arrow_moves_pointer) arrow_moves"
done
rm -rf "$TMP"

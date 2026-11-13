#!/usr/bin/env bash
set -e
APK="$1"
TMP=$(mktemp -d)
unzip -o -q "$APK" -d "$TMP"
for f in "$TMP"/classes*.dex; do
  echo "$(basename "$f"): close_app=$(strings "$f" | grep -c 'close app on phone')"
done
rm -rf "$TMP"

#!/bin/bash
set -u
cd /tmp
rm -rf dexui && mkdir -p dexui
APK=$(ls -1 /system/priv-app/SecSystemUI*/*.apk 2>/dev/null | head -1)
if [ -z "${APK:-}" ]; then APK=$(find /system -name "*.apk" -path "*ystemUI*" 2>/dev/null | head -1); fi
echo "APK=$APK"
echo "=== dex files containing touchpad ==="
unzip -l "$APK" 2>/dev/null | grep -iE "classes.*dex" | head
mkdir -p dexui/x && unzip -o -q "$APK" "classes*.dex" -d dexui/x 2>/dev/null
for d in dexui/x/classes*.dex; do
  n=$(strings -a "$d" 2>/dev/null | grep -ci "dextouchpad")
  echo "$(basename $d) touchpad-strings=$n"
done
echo "=== candidate class descriptors ==="
for d in dexui/x/classes*.dex; do
  strings -a "$d" 2>/dev/null | grep -iE "dextouchpad/|TouchpadActivity|TouchpadScroll|handleScroll" | sort -u | head -20
done

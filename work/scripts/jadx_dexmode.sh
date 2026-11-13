#!/bin/bash
set -e
export JAVA_HOME=/home/denniswung/tools/jdk-17.0.20.1+1
APK="/mnt/e/Dennis/GamePadDex复刻/work/apk/SecSettings.apk"
OUT=/tmp/secout
rm -rf "$OUT"
mkdir -p "$OUT"
~/tools/jadx-1.5.0/bin/jadx --single-class com.samsung.android.settings.desktop.DexModeSettingsFragment --single-class-output "$OUT/DexModeSettingsFragment.java" "$APK" 2>&1 | tail -5
echo "=== size ==="
ls -l "$OUT"

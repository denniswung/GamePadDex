#!/system/bin/sh
PKG=com.dennis.dexpad
APK=$(pm path $PKG | sed 's/package://' | head -1)
echo "apk=$APK"
sha256sum "$APK"
echo "--- helper ---"
sha256sum /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput
echo "--- versions ---"
dumpsys package $PKG | grep -m1 versionName
dumpsys package com.dennis.padtest | grep -m1 versionName
echo "--- prefs ---"
cat /data/misc/*/prefs/$PKG/dexpad.xml
echo "--- module ---"
grep -E 'version' /data/adb/modules/gpm_dex/module.prop

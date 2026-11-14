#!/system/bin/sh
PKG=com.dennis.dexpad
APK=$(pm path $PKG | sed 's/package://' | head -1)
echo "app_apk_sha: $(sha256sum "$APK" | cut -d' ' -f1)"
echo "helper_gpm:  $(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
echo "helper_mod:  $(sha256sum /data/adb/modules/gpm_dex/gpminput | cut -d' ' -f1)"
echo "module:      $(grep '^version=' /data/adb/modules/gpm_dex/module.prop) $(grep '^versionCode=' /data/adb/modules/gpm_dex/module.prop)"
echo "padtest:     $(dumpsys package com.dennis.padtest | grep -m1 versionName)"

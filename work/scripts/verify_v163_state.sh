#!/system/bin/sh
PKG=com.dennis.dexpad
APK=$(pm path $PKG | sed 's/package://' | head -1)
echo "apk:    $(sha256sum "$APK" | cut -c1-16)"
echo "helper: $(sha256sum /data/adb/gpm/gpminput | cut -c1-16)"
echo "module: $(sha256sum /data/adb/modules/gpm_dex/gpminput | cut -c1-16)"
grep -E '^version' /data/adb/modules/gpm_dex/module.prop
echo "app:    $(dumpsys package $PKG | grep -m1 versionName)"
echo "prefs:"; cat /data/misc/*/prefs/$PKG/dexpad.xml

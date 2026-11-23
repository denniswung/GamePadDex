#!/system/bin/sh
# v1.66 install/hash verification probe (read-only)
PKG=com.dennis.dexpad
echo "=== version ==="
dumpsys package $PKG | grep -m1 versionName
dumpsys package $PKG | grep -m1 versionCode
P=$(pm path $PKG | head -1 | cut -d: -f2)
echo "apk_path=$P"
echo "apk_sha256=$(sha256sum $P | cut -d' ' -f1)"
echo "apk_size=$(stat -c %s $P)"
echo "=== helper ==="
echo "gpm_sha256=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)"
echo "module_sha256=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | cut -d' ' -f1)"
echo "tmp_sha256=$(sha256sum /data/local/tmp/dexpad-v1.66.apk 2>/dev/null | cut -d' ' -f1)"
echo "=== module.prop ==="
grep -E '^(version|versionCode)=' /data/adb/modules/gpm_dex/module.prop
echo "=== display/rotation ==="
dumpsys display | grep -m1 mOverrideDisplayInfo
echo "user_rotation=$(settings get system user_rotation)"
echo "accelerometer_rotation=$(settings get system accelerometer_rotation)"
echo "pointer_speed=$(settings get system pointer_speed)"
echo "display_size_forced=$(settings get global display_size_forced)"
wm size
echo "rotation_lock=$(cmd window user-rotation 2>/dev/null | head -1)"
echo "=== procs ==="
echo "helper_pid=$(pidof gpminput)"
echo "app_pid=$(pidof com.dennis.dexpad)"
echo "=== wake ==="
dumpsys power | grep -m1 mWakefulness=
echo "=== input devices (uinput mouse) ==="
getevent -pl 2>/dev/null | grep -E 'name:|REL_X|REL_Y' | head -12

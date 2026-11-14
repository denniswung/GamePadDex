#!/system/bin/sh
# 版本一致性检查：设备上安装的 APK / 助手 是否就是当前编译产物
PKG=com.dennis.dexpad
echo "=== 设备上的应用 ==="
dumpsys package $PKG | grep -E 'versionName|versionCode' | head -2
APK=$(pm path $PKG | sed 's/package://' | head -1)
echo "apk path: $APK"
echo "apk sha256: $(sha256sum "$APK" | cut -d' ' -f1)"
echo
echo "=== 设备上的助手 ==="
ls -l /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput 2>/dev/null
echo "gpm sha256: $(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
echo "module sha256: $(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | cut -d' ' -f1)"
echo
echo "=== 运行中的助手 ==="
ps -A -o PID,NAME | grep gpminput | grep -v grep
echo
echo "=== 模块版本 ==="
cat /data/adb/modules/gpm_dex/module.prop 2>/dev/null | grep -E 'version'

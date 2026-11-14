#!/system/bin/sh
PKG=com.dennis.dexpad
echo "version: $(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
echo "--- prefs 关键项 ---"
grep -oE 'name="[a-z_0-9]+" value="[^"]*"' /data/misc/*/prefs/$PKG/dexpad.xml | grep -E 'target_package|btn_r3|mode_on'
echo "--- app pid ---"
pidof $PKG
echo "--- top ---"
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity
echo "--- 最近 open app 日志 ---"
logcat -d -s DexPad 2>/dev/null | grep -aE 'open app' | tail -2

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1

echo "=== SHARE(167) 开鼠标模式 ==="
logcat -c
$VG key 167 120 900 >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | grep -aE 'toggle|mode' | tail -3
echo "  prefs mode_on: $(grep -oE 'name=\"mode_on\" value=\"[^\"]*\"' /data/misc/*/prefs/$PKG/dexpad.xml)"

echo "=== L3 居中 ==="
logcat -c
$VG key 317 100 1000 >/dev/null 2>&1
sleep 1.2
logcat -d -s DexPad | grep -aE 'center pointer' | tail -2

echo "=== Y+L3 电源 ==="
: > /data/adb/gpm/helper.log
logcat -c
$VG combo 308 317 400 >/dev/null 2>&1
sleep 2
echo "  helper: $(grep -a 'POWER' /data/adb/gpm/helper.log | tail -1)"
echo "  wake: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"

echo "=== 杀前台（GUIDE 默认 alt+f4？先看 app 日志）==="
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
: > /data/adb/gpm/helper.log
logcat -c
$VG key 316 120 900 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad | tail -4
grep -aE 'FORCE_STOP|FORCE_KILL|ALTTAB|COMBO' /data/adb/gpm/helper.log | tail -3

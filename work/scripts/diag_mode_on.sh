#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1

echo "=== 按 SHARE 打开鼠标模式 ==="
logcat -c
$VG key 310 120 900 >/dev/null 2>&1
sleep 1.5
logcat -d -s DexPad | grep -aE 'toggle|mouse mode' | tail -3
echo "--- prefs ---"
grep -oE 'name="mode_on" value="[^"]*"' /data/misc/*/prefs/$PKG/dexpad.xml

echo
echo "=== 1) L3 居中 ==="
logcat -c
$VG key 317 100 1000 >/dev/null 2>&1
sleep 1.2
logcat -d -s DexPad | grep -aE 'center pointer|l3' | tail -3

echo
echo "=== 2) 电源键（Y+L3 = power） ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG combo 308 317 400 >/dev/null 2>&1
sleep 1.5
echo "  helper: $(grep -a 'POWER' /data/adb/gpm/helper.log | tail -1)"
echo "  wakefulness: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"

echo
echo "=== 3) 杀前台 ==="
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "  top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
: > /data/adb/gpm/helper.log
$VG key 315 100 900 >/dev/null 2>&1     # GUIDE? 先试 315
sleep 2
grep -aE 'FORCE_STOP|FORCE_KILL' /data/adb/gpm/helper.log | tail -2

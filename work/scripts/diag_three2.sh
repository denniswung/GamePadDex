#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
sleep 1

echo "=== 设备(mouse) ==="
grep -E 'N: Name=' /proc/bus/input/devices | grep -i 'Gamepad Mouse'

echo "=== 按 L3，看引擎/助手日志 ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
echo "--- DexPad ---"
logcat -d -s DexPad | tail -8
echo "--- helper ---"
tail -5 /data/adb/gpm/helper.log

echo "=== 电源键：helper p（等 6 秒，input 可能很久） ==="
logcat -c; : > /data/adb/gpm/helper.log
hcmd "p"
sleep 6
grep -a 'POWER' /data/adb/gpm/helper.log || echo "  (helper 没有输出 POWER)"
echo "  wakefulness: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"
echo "  若灭屏，再按一次唤醒"
printf 'p\n' | true
hcmd "p"; sleep 5
echo "  再次 wakefulness: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"

echo "=== 杀应用：helper f（等 6 秒） ==="
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
: > /data/adb/gpm/helper.log
hcmd "f"
sleep 6
grep -aE 'FORCE_STOP|FORCE_KILL|none' /data/adb/gpm/helper.log || echo "  (helper 没有输出 FORCE_*)"
pidof com.android.settings >/dev/null && echo "  settings 仍在" || echo "  settings 已死"

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

wake
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
echo "focus: $(dumpsys window 2>/dev/null | grep -m1 mCurrentFocus)"
echo "devices: $(grep -c 'Gamepad' /proc/bus/input/devices)"

# 让指针存在（推摇杆），确认 app 能收到 hover
logcat -c
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.8
echo "--- 摇杆后 hover ---"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -2 | sed 's/^.*PadProbe: /  /'

# 按 L3 居中
logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
echo "--- L3 后 hover ---"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -3 | sed 's/^.*PadProbe: /  /'
echo "--- 助手 ---"
grep -aE 'CENTER|POINTER' /data/adb/gpm/helper.log | tail -3
echo "--- 设备 ---"
grep -E 'N: Name=' /proc/bus/input/devices | grep -i gamepad

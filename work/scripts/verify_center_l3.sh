#!/system/bin/sh
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }
mice(){ grep -c 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

$VG stick 0 20000 300 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 4 20000 300 0 >/dev/null 2>&1
sleep 0.4
echo "角落: $(hover)  mice=$(mice)"

echo "--- 按 L3（真实按键映射） ---"
logcat -c
$VG key 317 100 1500 >/dev/null 2>&1
sleep 0.6
echo "  L3 后 mice=$(mice)"
echo "  助手: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"

# 左移一点把 hover 唤醒
$VG stick 0 -2500 250 0 >/dev/null 2>&1
sleep 0.6
H1=$(hover)
$VG stick 0 -2500 250 0 >/dev/null 2>&1
sleep 0.6
H2=$(hover)
echo "  左移1: $H1"
echo "  左移2: $H2"
echo "  期望: x≈1280 附近、y≈800"

#!/system/bin/sh
VG=/data/local/tmp/vgpad
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

$VG stick 0 20000 250 2000 >/dev/null 2>&1
sleep 0.4
logcat -c
$VG stick 0 20000 250 0 >/dev/null 2>&1
sleep 0.5
echo "--- 移动后的指针坐标（应用视角） ---"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -2 | sed 's/^.*PadProbe: /  /'
B=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
echo "  before=$B"

logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.0
echo "--- L3 后的指针坐标 ---"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -3 | sed 's/^.*PadProbe: /  /'
A=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
echo "  after=$A"
echo "--- 助手 ---"
grep -aE 'CENTER|POINTER' /data/adb/gpm/helper.log | tail -2
echo "--- 期望中心 ---"
echo "  wm size: $(wm size | tr '\n' ' ')"

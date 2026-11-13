#!/system/bin/sh
VG=/data/local/tmp/vgpad
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

# 连续两次小幅推杆（第一次用于恢复指针设备，第二次产生 hover）
$VG stick 0 20000 250 2000 >/dev/null 2>&1
sleep 0.4
logcat -c
$VG stick 4 12000 300 0 >/dev/null 2>&1
sleep 0.5
echo "--- hover after move ---"
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -3 | sed 's/^.*PadProbe: /  /'

echo "--- hover 500ms 后（应停止） ---"
sleep 0.5
logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed 's/^.*PadProbe: /  /'

echo "--- 记下当前坐标后按 L3 ---"
B=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.0
A=$(logcat -d -s PadProbe | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p')
echo "  before=$B  after=$A"
grep -aE 'CENTER' /data/adb/gpm/helper.log | tail -1

#!/system/bin/sh
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

$VG stick 0 20000 700 2000 >/dev/null 2>&1
sleep 0.4
$VG stick 4 20000 700 0 >/dev/null 2>&1
sleep 0.4
echo "A 角落: $(hover)"

$VG key 317 100 1500 >/dev/null 2>&1
sleep 3.5          # 等锁定期(3s)过去，否则摇杆被忽略
echo "   助手: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"

logcat -c
$VG stick 0 -8000 200 0 >/dev/null 2>&1
sleep 0.5
echo "B 居中后左移: $(hover)   ← 期望接近 1280,800"

logcat -c
$VG stick 0 -8000 200 0 >/dev/null 2>&1
sleep 0.5
echo "C 再左移: $(hover)"

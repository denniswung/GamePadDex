#!/system/bin/sh
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

$VG stick 0 20000 700 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 4 20000 700 0 >/dev/null 2>&1
sleep 0.4
echo "A 角落: $(hover)"

echo "--- input mouse motionevent MOVE 1158 452 ---"
input mouse motionevent MOVE 1158 452 2>&1 | head -3
sleep 0.6
echo "B 之后: $(hover)"
logcat -d -s PadProbe | grep -iE 'mouse' | tail -3 | sed 's/^.*PadProbe: /  /'

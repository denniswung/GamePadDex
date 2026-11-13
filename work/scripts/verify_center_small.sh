#!/system/bin/sh
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

# 小步移动，确保 hover 一直可见
$VG stick 0 20000 200 2000 >/dev/null 2>&1
sleep 0.4
echo "起点: $(hover)"

logcat -c
$VG key 317 100 1500 >/dev/null 2>&1
sleep 0.8
echo "L3 后: $(hover)"
echo "  助手: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"

# 每步只走 ~150ms 的小位移，看指针在哪个位置继续
for i in 1 2 3; do
  $VG stick 0 -120 150 200 >/dev/null 2>&1
  sleep 0.3
  echo "  左移$i: $(hover)"
done

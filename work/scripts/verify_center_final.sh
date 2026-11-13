#!/system/bin/sh
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

# 1) 先到右下角（长按移动，保证 hover 有输出）
$VG stick 0 20000 700 2000 >/dev/null 2>&1
sleep 0.4
$VG stick 4 20000 700 0 >/dev/null 2>&1
sleep 0.4
echo "A 角落: $(hover)"

# 2) 按 L3 居中
logcat -c
$VG key 317 100 1500 >/dev/null 2>&1
sleep 1.0
echo "   助手: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"

# 3) 小幅左移（长按 200ms），看指针从哪里继续
logcat -c
$VG stick 0 -8000 200 0 >/dev/null 2>&1
sleep 0.5
echo "B 左移后: $(hover)   ← 若居中成功应接近 1280,800 附近"

# 4) 再左移一次，确认单调递减
logcat -c
$VG stick 0 -8000 200 0 >/dev/null 2>&1
sleep 0.5
echo "C 再左移: $(hover)"

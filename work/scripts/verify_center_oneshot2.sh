#!/system/bin/sh
# 验证：一次性居中（无夹角），落点应接近屏幕中心
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
echo "wm size: $(wm size | tr '\n' ' ')  (中心应为 1280,800)"

# 先把指针推到右下角
$VG stick 0 20000 600 2000 >/dev/null 2>&1
sleep 0.2
$VG stick 4 20000 600 0 >/dev/null 2>&1
sleep 0.4
echo "A 起点: $(hover)"

logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 0.6
echo "   引擎: $(logcat -d -s DexPad | grep -a 'center pointer' | tail -1 | sed 's/^.*DexPad  : //')"

# 锁定期很短(300ms)，稍等后小步移动唤醒 hover
sleep 0.5
logcat -c
$VG stick 0 1500 120 0 >/dev/null 2>&1
sleep 0.4
echo "B 居中后小步: $(hover)   ← 应接近 1280,800"

logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 0.8
$VG stick 0 1500 120 0 >/dev/null 2>&1
sleep 0.4
echo "C 再居中一次: $(hover)   ← 应仍然接近 1280,800"

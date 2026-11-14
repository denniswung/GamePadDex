#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
echo "size=$(wm size | tr '\n' ' ')"

# 指针推到右下角
$VG stick 0 20000 500 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 4 20000 500 0 >/dev/null 2>&1
sleep 0.4
echo "A 角落 hover: $(hover)"

logcat -c
hcmd "q 1280 800"
sleep 1
echo "   helper: $(grep -a 'ABS_MOVE' /data/adb/gpm/helper.log | tail -1)"
echo "B 绝对定位后 hover: $(hover)  ← 期望 1280,800"

# 再动一下指针确认后续正常
logcat -c
$VG stick 0 800 100 0 >/dev/null 2>&1
sleep 0.4
echo "C 微动后 hover: $(hover)"

echo "--- 事件类型（看是否有 drag/click 副作用）---"
logcat -d -s PadProbe | grep -iE 'mouse|key' | tail -6 | sed 's/^.*PadProbe: /  /'

#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5

$VG key 317 100 1200 >/dev/null 2>&1     # 居中
sleep 1.2
logcat -c
$VG stick 0 20000 600 2000 >/dev/null 2>&1
sleep 0.5
echo "1) 移动后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

echo "--- 2) 空闲 10 秒（设备销毁，光标瞬间消失）---"
sleep 10
logcat -c
$VG stick 0 4000 200 2000 >/dev/null 2>&1
sleep 1.0
echo "3) 恢复日志: $(logcat -d -s DexPad | grep -aE 'pointer shown at last' | tail -1 | sed 's/^.*DexPad  : //')"
echo "   恢复后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
sleep 0.4
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "   点击落点: $(logcat -d -s PadProbe | grep -a 'click-down' | tail -1)"
echo "   helper: $(grep -aE 'MOUSE_REOPEN|POINTER|POSPTR' /data/adb/gpm/helper.log | tail -4 | tr '\n' '|')"

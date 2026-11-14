#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake; sleep 1
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
echo "top=$(top)"

$VG key 317 100 1200 >/dev/null 2>&1   # 居中 1280,800
sleep 1.2
logcat -c
$VG stick 0 20000 600 2000 >/dev/null 2>&1
$VG stick 1 20000 400 0 >/dev/null 2>&1
sleep 0.6
echo "移动后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

echo "--- 等 10 秒让它"停车隐藏" ---"
sleep 10
echo "隐藏日志: $(logcat -d -s DexPad | grep -aE 'pointer parked|pointer hidden' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "隐藏后 hover 还在动吗: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

logcat -c
echo "--- 推摇杆 0.5 秒（应一次出现在上次位置）---"
$VG stick 0 6000 500 2000 >/dev/null 2>&1
sleep 1.2
echo "恢复日志: $(logcat -d -s DexPad | grep -aE 'restored invisibly|pointer restored' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "恢复后 hover: $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
sleep 0.5
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "点击落点: $(logcat -d -s PadProbe | grep -a 'click-down' | tail -1)"

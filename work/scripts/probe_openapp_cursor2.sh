#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake; sleep 1

echo "=== 1) shell 域 am start -p 的返回 ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.example.piliplus 2>&1 | head -5
sleep 2.5
echo "top: $(top)"

echo
echo "=== 2) 助手 w 命令日志 ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "w com.example.piliplus" >/dev/null 2>&1
sleep 3
echo "helper log:"; tail -6 /data/adb/gpm/helper.log
echo "top: $(top)"

echo
echo "=== 3) 空闲隐藏后指针是否失步（d-pad 10 秒 -> 左摇杆）==="
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.ProbeActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
logcat -c
echo "--- 按 d-pad（不移动光标），等 10 秒让指针因空闲被隐藏 ---"
$VG hat 0 1 250 >/dev/null 2>&1
sleep 10
echo "--- 现在推左摇杆 1.5 秒 ---"
: > /data/adb/gpm/helper.log
$VG stick 0 20000 1500 2000 >/dev/null 2>&1
sleep 0.5
echo "helper: $(grep -aE 'MOUSE|GONE|h |j ' /data/adb/gpm/helper.log | tail -5 | tr '\n' '|')"
echo "engine ptr: $(logcat -d -s DexPad | grep -a 'ptr move' | tail -6 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "padtest hover: $(logcat -d -s PadProbe | grep -aE 'hover' | tail -5 | tr '\n' '|')"

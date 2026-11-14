#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
wake; sleep 1
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
echo "mode=$(modeval)"

echo "===== 1) R3 静音 ====="
: > /data/adb/gpm/helper.log; logcat -c
$VG key 318 120 800 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -a 'r3' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -aE 'KEYON|KEY |MUTE' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"

echo
echo "===== 2) d-pad 后按 A ====="
logcat -c
$VG hat 0 1 400 >/dev/null 2>&1 &
HAT=$!
sleep 0.3
$VG key 304 120 700 >/dev/null 2>&1
sleep 0.6
wait $HAT 2>/dev/null
echo "engine: $(logcat -d -s DexPad | grep -aE 'native navigation|DPAD_CENTER|left button' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

echo
echo "===== 3) GUIDE 杀前台 ====="
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
P1=$(pidof com.dennis.padtest)
echo "before pid=$P1 top=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
: > /data/adb/gpm/helper.log; logcat -c
$VG key 316 120 800 >/dev/null 2>&1
sleep 3
echo "engine: $(logcat -d -s DexPad | grep -aE 'guide|FORCE_STOP|force stop' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -aE 'FORCE_STOP|FORCE_KILL' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "after pid=$(pidof com.dennis.padtest || echo 已死)"

echo
echo "===== 4) X+↑ 音量加 ====="
: > /data/adb/gpm/helper.log; logcat -c
$VG combo 307 544 600 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -aE 'x\+up|volume|mix' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -aE 'KEYON|KCOMBO' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"

echo
echo "===== 5) X+LB / X+RB 滑动方向 ====="
: > /data/adb/gpm/helper.log
$VG combo 307 310 600 >/dev/null 2>&1
sleep 1
echo "X+LB: $(grep -a SWIPE /data/adb/gpm/helper.log | head -1)"
: > /data/adb/gpm/helper.log
$VG combo 307 311 600 >/dev/null 2>&1
sleep 1
echo "X+RB: $(grep -a SWIPE /data/adb/gpm/helper.log | head -1)"

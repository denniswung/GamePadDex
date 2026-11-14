#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

echo "=== d-pad 之后立刻按 LT（窗口内）==="
logcat -c
($VG hat 0 1 4000 >/dev/null 2>&1) &
sleep 0.35
echo "  d-pad 后: $(logcat -d -s DexPad | grep -a 'native navigation' | tail -1 | sed 's/^.*DexPad  : //')"
logcat -c; : > /data/adb/gpm/helper.log
$VG key 312 120 700 >/dev/null 2>&1
sleep 1.2
echo "  LT: $(logcat -d -s DexPad | grep -aE 'pinch|key combo|zoom' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -aE 'PINCH|COMBO' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"

echo
echo "=== 打开目标应用（A -> open_app）==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref target_package --es sval com.android.settings >/dev/null 2>&1
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button a --es mapped open_app >/dev/null 2>&1
sleep 1
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; : > /data/adb/gpm/helper.log
$VG key 304 120 900 >/dev/null 2>&1
sleep 3
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'open app' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button a --es mapped left_click >/dev/null 2>&1

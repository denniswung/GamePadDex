#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

echo "=== d-pad 模式下 LT 应该是 Ctrl +/- ==="
$VG hat 0 1 3000 >/dev/null 2>&1 &
sleep 0.6
logcat -c; : > /data/adb/gpm/helper.log
$VG key 312 150 800 >/dev/null 2>&1
sleep 1.2
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'pinch|native navigation|key combo' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -aE 'COMBO|PINCH|KEY 1' /data/adb/gpm/helper.log | tail -4 | tr '\n' '|')"
wait 2>/dev/null

echo
echo "=== 打开目标应用（R3 -> open_app）==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref target_package --es sval com.android.settings >/dev/null 2>&1
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button r3 --es mapped open_app >/dev/null 2>&1
sleep 0.8
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.2
logcat -c; : > /data/adb/gpm/helper.log
$VG key 318 150 900 >/dev/null 2>&1
sleep 2.5
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'open app' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button r3 --es mapped volume_mute >/dev/null 2>&1

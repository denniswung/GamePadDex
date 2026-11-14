#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2

# 把光标移到屏幕中部
$VG stick 0 12000 300 2000 >/dev/null 2>&1
sleep 0.6

echo
echo "=== 1) A 键 = 屏幕点击（真实触摸） ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG key 304 120 900 >/dev/null 2>&1
sleep 1
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'left touch|DPAD_CENTER' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -aE 'TOUCH (down|up)' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  应用: $(logcat -d -s PadProbe | grep -aiE 'touch-(down|up)' | tail -2 | sed 's/^.*PadProbe: //' | tr '\n' '|')"

echo
echo "=== 2) A 长按（按住 1 秒） ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG hold 304 1000 >/dev/null 2>&1
sleep 1.6
echo "  助手: $(grep -aE 'TOUCH (down|up)' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"

echo
echo "=== 3) LT = 双指缩放（按住 1 秒） ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG hold 312 1000 >/dev/null 2>&1
sleep 1.6
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'pinch' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -aE 'PINCH' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"

echo
echo "=== 4) d-pad 模式下的缩放 = Ctrl +/- ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG hat 0 1 0 0 >/dev/null 2>&1
sleep 0.5
$VG key 312 120 900 >/dev/null 2>&1
sleep 1
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'native navigation|pinch' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -aE 'COMBO|PINCH' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  (d-pad 模式应看到 COMBO/CTRL，而不是 PINCH)"

echo
echo "=== 5) 打开目标应用 ==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es pref target_package --es sval com.android.settings >/dev/null 2>&1
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button r3 --es mapped open_app >/dev/null 2>&1
sleep 0.8
am force-stop com.dennis.padtest 2>/dev/null
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1
logcat -c
$VG key 318 120 900 >/dev/null 2>&1
sleep 2.5
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'open app' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
# 还原 r3 映射
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es button r3 --es mapped volume_mute >/dev/null 2>&1

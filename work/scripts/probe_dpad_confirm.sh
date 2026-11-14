#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

wake; sleep 1
echo "mode=$(modeval)"
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
echo "before: $(top)"

echo "=== 1) d-pad 下两下（聚焦），马上按 A ==="
logcat -c; : > /data/adb/gpm/helper.log
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.15
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.15
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'native navigation|DPAD_CENTER|left button down' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -aE 'KEYUIN|ARROW' /data/adb/gpm/helper.log | tail -4 | tr '\n' '|')"
echo "after : $(top)"

echo
echo "=== 2) d-pad 后等 2 秒再按 A（焦点窗口过期）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.2
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'native navigation OFF|DPAD_CENTER|left button down' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after : $(top)"

echo
echo "=== 3) 直接长按 A（确认/长按菜单）+ d-pad 后 ==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
$VG hat 0 1 200 >/dev/null 2>&1
$VG key 304 600 200 >/dev/null 2>&1
sleep 1.2
echo "after : $(top)"

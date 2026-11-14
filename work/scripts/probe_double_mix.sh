#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

wake; sleep 1
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

echo "=== 1) X 双击 -> 多任务（默认 dbl_x=recents）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
echo "before: $(top)"
logcat -c; : > /data/adb/gpm/helper.log
$VG double 307 60 120 >/dev/null 2>&1
sleep 2
echo "engine: $(logcat -d -s DexPad | grep -aE 'double x|recents' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -aE 'KEYUIN' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "after : $(top)"

echo
echo "=== 2) 慢一点的双击（间隔 300ms）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG double 307 70 300 >/dev/null 2>&1
sleep 2
echo "engine: $(logcat -d -s DexPad | grep -aE 'double x|recents' | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after : $(top)"

echo
echo "=== 3) X+LB / X+RB 方向（对调后）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
: > /data/adb/gpm/helper.log
$VG combo 307 310 700 >/dev/null 2>&1
sleep 1.2
echo "X+LB: $(grep -a SWIPE /data/adb/gpm/helper.log | head -1)"
: > /data/adb/gpm/helper.log
$VG combo 307 311 700 >/dev/null 2>&1
sleep 1.2
echo "X+RB: $(grep -a SWIPE /data/adb/gpm/helper.log | head -1)"

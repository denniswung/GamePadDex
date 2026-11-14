#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
leftmode(){ grep -oE 'name="left_touch" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
echo "mode_on=$(modeval)  left_touch=$(leftmode)"
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
echo "起始前台: $(top)"

# 用左摇杆移动光标（axis 0/1 = AXIS_X/Y），等几秒避免空闲隐藏干扰
$VG stick 0 12000 400 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 1 6000 300 0 >/dev/null 2>&1
sleep 0.5
echo "--- 按 A ---"
: > /data/adb/gpm/helper.log
logcat -c
$VG key 304 120 900 >/dev/null 2>&1
sleep 2
echo "引擎日志:"
logcat -d -s DexPad | tail -8
echo "助手日志(按钮/触摸):"
grep -aE 'BTN|TOUCH|MOUSE' /data/adb/gpm/helper.log | tail -4
echo "之后前台: $(top)"

echo
echo "--- 再按一次 A（间隔 2 秒）---"
sleep 1
logcat -c
$VG key 304 120 900 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad | tail -4
echo "之后前台: $(top)"

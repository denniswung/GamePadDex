#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
size(){ wc -c < "$1" 2>/dev/null; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)  wake=$(dumpsys power | grep -m1 -o 'mWakefulness=[A-Za-z]*')"

am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
screencap -p /data/local/tmp/r0.png 2>/dev/null
echo "起始截图: $(size /data/local/tmp/r0.png) 字节"

echo "--- 右摇杆向下 (axis 13 = +20000) ---"
: > /data/adb/gpm/helper.log
$VG stick 13 20000 1500 2000 >/dev/null 2>&1
sleep 0.6
screencap -p /data/local/tmp/r1.png 2>/dev/null
echo "  SWIPE: $(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  截图: $(size /data/local/tmp/r1.png)"

echo "--- 右摇杆向上 (axis 13 = -20000) ---"
: > /data/adb/gpm/helper.log
$VG stick 13 -20000 1500 0 >/dev/null 2>&1
sleep 0.6
screencap -p /data/local/tmp/r2.png 2>/dev/null
echo "  SWIPE: $(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "  截图: $(size /data/local/tmp/r2.png)"

echo "--- 对比（字节数不同=页面确实滚动了）---"
echo "  r0=$(size /data/local/tmp/r0.png) r1=$(size /data/local/tmp/r1.png) r2=$(size /data/local/tmp/r2.png)"

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

echo "=== 杀应用：前台放一个普通 app（padtest），按 GUIDE(316) ==="
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
echo "  进程: $(pidof com.dennis.padtest)"
: > /data/adb/gpm/helper.log
$VG key 316 120 800 >/dev/null 2>&1
sleep 3
echo "  helper:"; grep -aE 'CLOSE_APP' /data/adb/gpm/helper.log | tail -3
echo "  之后进程: $(pidof com.dennis.padtest || echo '已死')"
echo "  之后前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"

echo
echo "=== 电源键：Y+L3 ==="
echo "  之前: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"
: > /data/adb/gpm/helper.log
$VG combo 308 317 400 >/dev/null 2>&1
sleep 2
echo "  helper: $(grep -a 'POWER' /data/adb/gpm/helper.log | tail -1)"
echo "  之后: $(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')"
sleep 1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1

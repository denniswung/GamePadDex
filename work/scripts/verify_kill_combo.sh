#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
echo "前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')  进程: $(pidof com.dennis.padtest)"

: > /data/adb/gpm/helper.log
logcat -c
echo "--- 按 X+GUIDE（设计上的强制停止组合）---"
$VG combo 307 316 1200 >/dev/null 2>&1
sleep 3
logcat -d -s DexPad | grep -aiE 'force|guide' | tail -4
grep -aE 'FORCE_STOP|CLOSE_APP|FORCE_KILL' /data/adb/gpm/helper.log | tail -3
echo "之后进程: $(pidof com.dennis.padtest || echo '已死')"
echo "之后前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"

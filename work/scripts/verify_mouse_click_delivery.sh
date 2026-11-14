#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
echo "前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"

# 把光标推到屏幕左上角（长时间推），再往右下走一段，得到一个大致确定的位置
$VG stick 0 -20000 2500 2000 >/dev/null 2>&1
sleep 0.3
$VG stick 1 -20000 2500 0 >/dev/null 2>&1
sleep 0.3
$VG stick 0 9000 500 0 >/dev/null 2>&1
sleep 0.3
$VG stick 1 9000 500 0 >/dev/null 2>&1
sleep 0.4

logcat -c
: > /data/adb/gpm/helper.log
$VG key 304 120 900 >/dev/null 2>&1
sleep 1.2
echo "--- padtest 收到的事件 ---"
logcat -d -s PadProbe | grep -aiE 'mouse|click' | tail -4
echo "--- 引擎 ---"
logcat -d -s DexPad | grep -aE 'left button|hover|ptr move' | tail -4

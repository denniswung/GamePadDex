#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake; sleep 1
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

echo "=== Y 键是否真的回主屏 ==="
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2
echo "before: $(top)"
: > /data/adb/gpm/helper.log
$VG key 308 120 900 >/dev/null 2>&1
sleep 2
echo "after : $(top)"
echo "helper: $(grep -a 'KEYON' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"

echo
echo "=== 音量键是否真的生效（X+↑）==="
V0=$(dumpsys audio 2>/dev/null | grep -A3 'STREAM_MUSIC' | grep -m1 'streamVolume:' )
echo "before: $V0"
$VG key 308 100 500 >/dev/null 2>&1
sleep 1.5
$VG combo 307 544 500 >/dev/null 2>&1
sleep 0.4
$VG combo 307 544 500 >/dev/null 2>&1
sleep 1
V1=$(dumpsys audio 2>/dev/null | grep -A3 'STREAM_MUSIC' | grep -m1 'streamVolume:' )
echo "after : $V1"
echo "helper: $(grep -a 'KEYON' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }

wake; sleep 1
echo "=== A) 触摸点击模式 ==="
am force-stop $PKG; sleep 1
awk 'BEGIN{d=0} /<\/map>/ { if(!d){ print "    <boolean name=\"left_touch\" value=\"true\" />"; d=1 } } { print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
grep left_touch "$XML"
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
: > /data/adb/gpm/helper.log; logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
echo "helper TOUCH: $(grep -ac 'TOUCH' /data/adb/gpm/helper.log)"
echo "engine: $(logcat -d -s DexPad | grep -aE 'A pressed|left touch|left button' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

echo
echo "=== B) 摇杆是否能退出导航模式（deadzone 相关）==="
am force-stop $PKG; sleep 1
awk '!/name="left_touch"/' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 9000 300 0 >/dev/null 2>&1
sleep 0.6
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -aE 'native navigation|A pressed|left button down' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

echo
echo "=== C) 摇杆大幅推（20000）==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 20000 300 0 >/dev/null 2>&1
sleep 0.6
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
echo "engine: $(logcat -d -s DexPad | grep -aE 'native navigation|A pressed|left button down' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

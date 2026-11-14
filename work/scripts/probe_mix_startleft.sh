#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }

wake; sleep 1
grep -oE 'name="mix_[0-9]+_[a-z]+" value="[^"]*"' "$XML" 2>/dev/null | head -12
echo "----"
am force-stop $PKG; sleep 1
awk 'BEGIN{d=0}
/<\/map>/ { if(!d){ printf "    <string name=\"mix_9_keys\">start+left</string>\n"; printf "    <string name=\"mix_9_action\">open_app</string>\n"; printf "    <string name=\"mix_9_value\">com.android.settings</string>\n"; d=1 } }
{ print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5

echo "=== START + 左（keyhat 315 -1）==="
logcat -c; : > /data/adb/gpm/helper.log
$VG keyhat 315 -1 400 >/dev/null 2>&1
sleep 2.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|open app|switch_app|button left|button start' | tail -8 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"
echo "helper: $(grep -aE 'OPEN_APP|open' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"

echo
echo "=== 对照：START + 右（keyhat 315 1）==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1
logcat -c
$VG keyhat 315 1 400 >/dev/null 2>&1
sleep 2.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|open app' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

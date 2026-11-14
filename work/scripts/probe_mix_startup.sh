#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }

wake; sleep 1
echo "当前 prefs 里的 mix 槽："
grep -oE 'name="mix_[0-9]+_[a-z]+" value="[^"]*"' "$XML" 2>/dev/null | head -20
echo "----"

# 找一个空槽位
SLOT=""; for i in $(seq 0 23); do grep -q "name=\"mix_${i}_keys\"" "$XML" 2>/dev/null || { SLOT=$i; break; }; done
[ -z "$SLOT" ] && SLOT=20
echo "写入 mix_$SLOT = start+up -> open_app(com.android.settings)"
am force-stop $PKG; sleep 1
awk -v s="$SLOT" 'BEGIN{d=0}
/<\/map>/ { if(!d){ printf "    <string name=\"mix_%s_keys\">start+up</string>\n", s; printf "    <string name=\"mix_%s_action\">open_app</string>\n", s; printf "    <string name=\"mix_%s_value\">com.android.settings</string>\n", s; d=1 } }
{ print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5

echo "=== 1) START 按住 + HAT=-1（上）==="
logcat -c; : > /data/adb/gpm/helper.log
$VG keyhat 315 -1 400 >/dev/null 2>&1
sleep 2.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|open app|switch_app|up down|button up' | tail -6 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"

echo
echo "=== 2) START 按住 + HAT=1（下）==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1
logcat -c
$VG keyhat 315 1 400 >/dev/null 2>&1
sleep 2.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|open app|switch_app|button down' | tail -6 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"

echo
echo "=== 3) 普通按键组合对照：X+UP 是否触发（音量+）==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1
logcat -c
$VG keyhat 307 -1 400 >/dev/null 2>&1
sleep 1.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|volume' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

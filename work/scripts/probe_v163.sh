#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }

wake; sleep 1
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

echo "=== 1) 打开应用：助手 w 直接启动 PiliPlus ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "w com.example.piliplus" >/dev/null 2>&1
sleep 3
echo "helper: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "top: $(top)"

echo
echo "=== 2) Start + 上 打开 PiliPlus（组合键）==="
am force-stop $PKG; sleep 1
awk 'BEGIN{d=0}
/<\/map>/ { if(!d){ printf "    <string name=\"mix_11_keys\">start+up</string>\n"; printf "    <string name=\"mix_11_action\">open_app</string>\n"; printf "    <string name=\"mix_11_value\">com.example.piliplus</string>\n"; d=1 } }
{ print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; : > /data/adb/gpm/helper.log
$VG keyvhat 315 -1 500 >/dev/null 2>&1
sleep 3
echo "engine: $(logcat -d -s DexPad | grep -aE 'mix|open app' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "top: $(top)"

echo
echo "=== 3) d-pad 后空闲隐藏 -> 摇杆恢复后光标是否卡边界 ==="
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.ProbeActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
$VG hat 0 1 250 >/dev/null 2>&1
sleep 10
logcat -c
$VG stick 0 20000 1500 2000 >/dev/null 2>&1
$VG stick 1 20000 1200 0 >/dev/null 2>&1
sleep 0.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'pointer shown|re-centred|ptr move' | tail -8 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "padtest hover（真实光标是否在动）: $(logcat -d -s PadProbe | grep -aE 'hover' | tail -4 | tr '\n' '|')"

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake; sleep 1

echo "=== 当前 prefs ==="; cat "$XML"
echo "=== 写入 btn_y=open_app / par_y=settings ==="
am force-stop $PKG; sleep 1
awk 'BEGIN{d=0}
/<\/map>/ { if(!d){ printf "    <string name=\"btn_y\">open_app</string>\n"; printf "    <string name=\"par_y\">com.android.settings</string>\n"; d=1 } }
{ print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
echo "--- 写入后 ---"; cat "$XML"
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
echo "=== 按 Y ==="
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; : > /data/adb/gpm/helper.log
$VG hold 308 800 >/dev/null 2>&1
sleep 3
echo "engine: $(logcat -d -s DexPad | grep -aE 'button y|open app' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "helper: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"
echo "top: $(top)"

echo "=== 清理 ==="
am force-stop $PKG; sleep 1
awk '!/name="btn_y"/ && !/name="par_y"/' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
cat "$XML"

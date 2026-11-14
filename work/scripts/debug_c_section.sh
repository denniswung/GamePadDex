#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }

# 清理测试残留映射
am force-stop $PKG; sleep 1
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
awk '!/name="btn_y"/ && !/name="par_y"/ && !/name="left_touch"/' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
echo "prefs:"; cat "$XML"
wake; sleep 1
echo "mode=$(grep -oE 'name=\"mode_on\" value=\"[a-z]+\"' "$XML" | sed 's/.*value=\"//;s/\"//')"

am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2
L=$(wc -l < /data/adb/gpm/helper.log)
B=$(top)
: > /data/adb/gpm/helper.log
$VG key 308 150 1200 >/dev/null 2>&1
sleep 2.5
echo "Y: $B -> $(top)"
echo "--- helper ---"; grep -aE 'KEYUIN|KEY ' /data/adb/gpm/helper.log | tail -4
echo "--- engine ---"; logcat -d -s DexPad | grep -aE 'button y|home on|mix' | tail -4

echo
echo "=== SELECT 通知栏 ==="
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
wake; sleep 0.5
screencap -p /data/local/tmp/q0.png 2>/dev/null
: > /data/adb/gpm/helper.log
$VG key 314 150 1200 >/dev/null 2>&1
sleep 2.5
screencap -p /data/local/tmp/q1.png 2>/dev/null
echo "screenshot: $(wc -c < /data/local/tmp/q0.png) -> $(wc -c < /data/local/tmp/q1.png)"
echo "--- helper ---"; grep -aE 'KEYUIN|NOTIF|KEY ' /data/adb/gpm/helper.log | tail -4
echo "--- engine ---"; logcat -d -s DexPad | grep -aE 'notification' | tail -2
echo "--- expanded panel ---"; dumpsys window 2>/dev/null | grep -m1 'mExpandedPanel'

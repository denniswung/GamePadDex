#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
size(){ wc -c < "$1" 2>/dev/null; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

echo
echo "=== 1) 右摇杆滚动：先往下滚到底，再往上滚 ==="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
screencap -p /data/local/tmp/s0.png 2>/dev/null
: > /data/adb/gpm/helper.log
$VG stick 1 20000 1800 2000 >/dev/null 2>&1     # 右摇杆向下（axis 1 = RY? 先用1试）
sleep 0.5
screencap -p /data/local/tmp/s1.png 2>/dev/null
echo "  下滚后 SWIPE: $(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
: > /data/adb/gpm/helper.log
$VG stick 1 -20000 1800 0 >/dev/null 2>&1        # 右摇杆向上
sleep 0.5
screencap -p /data/local/tmp/s2.png 2>/dev/null
echo "  上滚后 SWIPE: $(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  截图字节: $(size /data/local/tmp/s0.png) -> $(size /data/local/tmp/s1.png) -> $(size /data/local/tmp/s2.png)"

echo
echo "=== 2) D-pad 连发（按住 1.5 秒） ==="
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.KeyTestActivity >/dev/null 2>&1
sleep 2
: > /data/adb/gpm/helper.log
logcat -c
$VG hat 0 1 1600 >/dev/null 2>&1
sleep 2.2
CNT=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
echo "  助手 ARROW 次数: $CNT（期望 > 1，说明连发）"
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'arrow' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
grep -a 'ARROW' /data/adb/gpm/helper.log | tail -4

echo
echo "=== 3) 每个按键各自的目标应用（R3 -> open_app, par_r3=settings） ==="
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
am force-stop $PKG; sleep 1
awk 'BEGIN{done=0}
/<\/map>/ { if(!done){ print "    <string name=\"btn_r3\">open_app</string>"; print "    <string name=\"par_r3\">com.android.settings</string>"; done=1 } }
{ print }' "$XML" > /data/local/tmp/p2.xml
cat /data/local/tmp/p2.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
logcat -c
$VG hold 318 900 >/dev/null 2>&1
sleep 2.5
echo "  引擎: $(logcat -d -s DexPad | grep -aE 'open app|button r3' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "  助手: $(grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2 | tr '\n' '|')"
echo "  前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"

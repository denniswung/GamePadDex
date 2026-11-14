#!/system/bin/sh
PKG=com.dennis.dexpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
echo "xml=$XML"
[ -z "$XML" ] && exit 1

echo "--- before ---"
cat "$XML"

am force-stop $PKG; sleep 1

# 用 awk 在 </map> 前插入两个键（不依赖 sed 的转义）
awk 'BEGIN{done=0}
/<\/map>/ {
  print "    <string name=\"target_package\">com.android.settings</string>";
  print "    <string name=\"btn_r3\">open_app</string>";
}
{ print }' "$XML" > /data/local/tmp/dexpad_new.xml

cp /data/local/tmp/dexpad_new.xml "$XML"
chown $(stat -c '%u:%g' "$XML") "$XML" 2>/dev/null
chmod 600 "$XML"
echo "--- after ---"
cat "$XML"

sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
echo "--- app pid: $(pidof $PKG) ---"
input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 1.5
logcat -c; : > /data/adb/gpm/helper.log
/data/local/tmp/vgpad key 318 120 900 >/dev/null 2>&1
sleep 3
echo "--- 引擎 ---"
logcat -d -s DexPad | grep -aE 'open app|button r3' | tail -3
echo "--- 助手 ---"
grep -a 'OPEN_APP' /data/adb/gpm/helper.log | tail -2
echo "--- 前台 ---"
dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity

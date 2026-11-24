#!/system/bin/sh
# debug: does the engine pick up v_touch_scroll=false from the prefs XML?
P=/data/misc/10/prefs/com.dennis.dexpad/dexpad.xml
echo "before: $(grep -o 'v_touch_scroll" value="[a-z]*"' $P)"
am force-stop com.dennis.dexpad; sleep 1
sed -i 's/v_touch_scroll" value="[a-z]*"/v_touch_scroll" value="false"/' $P
echo "after sed: $(grep -o 'v_touch_scroll" value="[a-z]*"' $P)"
am start-foreground-service -n com.dennis.dexpad/.EngineService; sleep 4
echo "after start: $(grep -o 'v_touch_scroll" value="[a-z]*"' $P) pid=$(pidof com.dennis.dexpad)"
echo "json: $(grep -o '\"v_touch_scroll\": [a-z]*' /data/data/com.dennis.dexpad/files/dexpad-config.json 2>/dev/null)"
echo "studir: $(ls /data/data/com.dennis.dexpad/shared_prefs 2>/dev/null)"
logcat -c
/data/local/tmp/vgpad key 311 600 400 >/dev/null 2>&1
sleep 1.5
echo "mode lines:"
logcat -d -s DexPad | grep -a 'hold-scroll\|drag start' | tail -3
echo "wheel=$(grep -ac '^WHEEL' /data/adb/gpm/helper.log) swipe=$(grep -ac '^SWIPE ' /data/adb/gpm/helper.log)"
echo "restore:"
am force-stop com.dennis.dexpad; sleep 1
sed -i 's/v_touch_scroll" value="[a-z]*"/v_touch_scroll" value="true"/' $P
am start-foreground-service -n com.dennis.dexpad/.EngineService; sleep 3
echo "final: $(grep -o 'v_touch_scroll" value="[a-z]*"' $P) pid=$(pidof com.dennis.dexpad)"

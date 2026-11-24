echo "count_alt=$(grep -acE 'SWIPE|WHEEL' /data/adb/gpm/helper.log)"
echo "count_swipe=$(grep -ac 'SWIPE' /data/adb/gpm/helper.log)"
echo "count_wheel=$(grep -ac 'WHEEL' /data/adb/gpm/helper.log)"
grep -ao 'v_touch_scroll" value="[a-z]*"' /data/misc/*/prefs/com.dennis.dexpad/dexpad.xml
echo "helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) vg=$(pidof vgpad)"
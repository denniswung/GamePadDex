#!/system/bin/sh
PKG=com.dennis.dexpad
dbg() { am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
# wheel mode
dbg --es pref v_touch_scroll --ez bval false
sleep 0.5
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
logcat -c
L=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 600 2500 >/dev/null 2>&1
sleep 3
echo "--- helper focus/swipe ---"
tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -aE 'FOCUS|SWIPE|WHEEL' | head -6
echo "--- app ---"
logcat -d -s DexPad 2>/dev/null | grep -E 'focus|wheel|lat' | tail -6
echo "--- focus.txt ---"
cat /data/adb/gpm/focus.txt 2>/dev/null || echo none
dbg --es pref v_touch_scroll --ez bval true

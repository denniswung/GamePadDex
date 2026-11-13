#!/system/bin/sh
PKG=com.dennis.dexpad
dbg() { am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
dbg --es pref focus_scroll --ez bval false
sleep 0.6
dbg --es pref focus_scroll --ez bval true
sleep 0.6
dbg --es pref v_touch_scroll --ez bval false
sleep 0.6
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
logcat -c
L=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 7000 2500 >/dev/null 2>&1
sleep 1.5
echo "--- helper ---"
tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -aE 'FOCUS|WHEEL' | head -8
echo "--- app ---"
logcat -d -s DexPad 2>/dev/null | grep -iE 'focus|wheel' | tail -5
dbg --es pref v_touch_scroll --ez bval true

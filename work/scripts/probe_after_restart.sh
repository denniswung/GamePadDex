#!/system/bin/sh
sh /data/local/tmp/dexpad_restart_clean.sh >/dev/null 2>&1
sleep 6
PREF=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
grep mode_on "$PREF"
logcat -d -s DexPad 2>/dev/null | grep -E 'mouse mode|hb ' | tail -3
am start -n com.dennis.dexpad/.PointerProbeActivity >/dev/null 2>&1
sleep 2
/data/local/tmp/vgpad stick 0 8000 500 1000 >/dev/null 2>&1
sleep 0.6
uiautomator dump /sdcard/x.xml >/dev/null 2>&1
grep -o 'text="x=[^"]*"' /sdcard/x.xml | head -1

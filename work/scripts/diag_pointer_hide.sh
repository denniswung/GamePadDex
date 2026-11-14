#!/system/bin/sh
PKG=com.dennis.dexpad
echo "--- engine pointer logs ---"
logcat -d -s DexPad | grep -aE 'pointer|idle' | tail -10
echo "--- helper pointer logs ---"
grep -aE 'MOUSE_REOPEN|POINTER|^h$|^j$|^h |^j ' /data/adb/gpm/helper.log | tail -10
echo "--- idle pref ---"
grep -E 'idle' /data/misc/*/prefs/$PKG/dexpad.xml
echo "--- padtest hover count ---"
logcat -d -s PadProbe | grep -acE 'hover'
logcat -d -s PadProbe | tail -3

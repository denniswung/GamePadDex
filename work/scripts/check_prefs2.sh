#!/system/bin/sh
P=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
grep -E 'name="(enabled|phone_mode|auto_dex|force_phone|v_touch_scroll)"' "$P"
echo "--- engine startup logs ---"
logcat -d -s DexPad 2>/dev/null | grep -E 'mouse mode|engine started' | tail -4
echo "--- button log ---"
logcat -d -s DexPad 2>/dev/null | grep -E 'button a|left button' | tail -3

#!/system/bin/sh
PKG=com.dennis.dexpad
v2() { am broadcast -a $PKG.V2 -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
log() { logcat -d -s DexPadV2 2>/dev/null; }

v2 --ez clear_combos true
v2 --es combo_leader x --es combo_second a --es combo_action volume_up
v2 --es combo_leader a --es combo_second x --es combo_action volume_down
v2 --es key_button a --es key_action left_click --es key_hold "" --es key_double ""
sleep 1
echo "== stored combos =="
grep -o 'combos.*' /data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad_v2.xml | head -1
echo "== chord =="
logcat -c
/data/local/tmp/vgpad combo 307 304 500 >/dev/null 2>&1
sleep 1.5
log | tail -6

#!/system/bin/sh
B=com.dennis.dexpad
P=/data/misc/f7a4f515-2be2-4c14-959e-dc82d9b3e434/prefs/com.dennis.dexpad/dexpad.xml
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval true >/dev/null 2>&1
sleep 1
echo "pref: $(grep force_phone $P)"
logcat -c
/data/local/tmp/vgpad key 317 300 2600 >/dev/null 2>&1
sleep 1
echo "center: $(grep CENTER /data/adb/gpm/helper.log | tail -1)"
echo "engine: $(logcat -d -s DexPad 2>/dev/null | grep -E 'cursor centered' | tail -1)"
dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval false >/dev/null 2>&1
echo "restored: $(grep force_phone $P)"

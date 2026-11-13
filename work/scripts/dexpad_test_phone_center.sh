#!/system/bin/sh
B=com.dennis.dexpad
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval true >/dev/null 2>&1
input keyevent KEYCODE_WAKEUP
wm dismiss-keyguard
am start --display 0 -n $B/.ConfigActivity >/dev/null 2>&1
sleep 2
logcat -c
/data/local/tmp/vgpad key 317 300 2600 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -2
dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval false >/dev/null 2>&1

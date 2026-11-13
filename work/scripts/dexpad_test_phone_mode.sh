#!/system/bin/sh
B=com.dennis.dexpad
echo "== enable force_phone (debug pref) =="
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval true >/dev/null 2>&1
sleep 1
input keyevent KEYCODE_WAKEUP
wm dismiss-keyguard
am start --display 0 -n $B/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
echo "== L3 center (phone) =="
/data/local/tmp/vgpad key 317 300 2600 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -2
logcat -d -s DexPad 2>/dev/null | grep -E 'cursor centered' | tail -1
echo "== SELECT maximize (phone) =="
/data/local/tmp/vgpad key 314 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'maximize' | tail -1
echo "== X recents (phone) =="
logcat -c
/data/local/tmp/vgpad key 307 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'recents on display' | tail -1
grep KEYON /data/adb/gpm/helper.log | tail -1
echo "== START switch (phone) =="
logcat -c
/data/local/tmp/vgpad key 315 300 2600 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'switch app' | tail -1
grep SWITCH /data/adb/gpm/helper.log | tail -1
echo "== right stick down (phone swipe) =="
/data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1
sleep 1
grep SWIPE /data/adb/gpm/helper.log | tail -1
echo "== restore force_phone =="
am broadcast -a $B.DEBUG -n $B/.DebugReceiver --es pref force_phone --ez bval false >/dev/null 2>&1

#!/system/bin/sh
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
input keyevent KEYCODE_WAKEUP
logcat -c
grep -c GONE_EVT /data/adb/gpm/helper.log > /tmp/g0
/data/local/tmp/vgpad hat 0 1 5000 2600 >/dev/null 2>&1 &
sleep 3.5
echo "helper log after dpad:"
grep -E 'GONE_EVT|GRABBED|GONE 0' /data/adb/gpm/helper.log | tail -4
logcat -d -s DexPad 2>/dev/null | grep -E 'native passthrough|arrow key' | tail -2
echo "== stick while pad still held =="
logcat -c
/data/local/tmp/vgpad stick 0 20000 600 300 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'native passthrough' | tail -2
grep -E 'GRABBED|GONE 0' /data/adb/gpm/helper.log | tail -3
wait

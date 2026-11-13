#!/system/bin/sh
logcat -c
/data/local/tmp/vgpad hat 0 -1 500 5000 >/dev/null 2>&1 &
wait
sleep 1
logcat -d 2>/dev/null | grep -E 'button up|arrow key|DexPadKeys' | tail -5
grep KEYON /data/adb/gpm/helper.log | tail -2

#!/system/bin/sh
echo "== engine thread priorities =="
PID=$(pidof com.dennis.dexpad)
ps -T -p "$PID" -o TID,NI,PRI,CMD 2>/dev/null | grep -E 'dexpad|NI' | head -6
echo "== helper nice =="
ps -o PID,NI,PRI,NAME -p $(pidof gpminput) 2>/dev/null
echo "== X+LB swipe (constant gesture) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 310 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d 2>/dev/null | grep -E 'swipe|mix 4' | tail -3
grep SWIPE /data/adb/gpm/helper.log | tail -2
echo "== X+Y newly added combo =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 308 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d 2>/dev/null | grep -E 'mix 8|swipe' | tail -3
grep SWIPE /data/adb/gpm/helper.log | tail -1

#!/system/bin/sh
for p in $(pidof gpminput); do kill -9 "$p" 2>/dev/null; done
for p in $(pidof com.dennis.dexpad); do kill -9 "$p" 2>/dev/null; done
sleep 2
sh /data/local/tmp/dexpad_start.sh >/dev/null 2>&1
sleep 6
logcat -c
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad DexPadLink 2>/dev/null | tail -8

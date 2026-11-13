#!/system/bin/sh
# L3 center cursor, then X+LT / X+RT horizontal swipe combos
echo "== L3 center =="
logcat -c
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -2
logcat -d -s DexPad 2>/dev/null | grep -E 'cursor centered' | tail -1

echo "== X + LT (swipe left) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad stick 2 30000 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe|zoom|deferred' | tail -6
grep SWIPE /data/adb/gpm/helper.log | tail -2

echo "== X + RT (swipe right) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad stick 5 30000 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe|zoom|deferred' | tail -6
grep SWIPE /data/adb/gpm/helper.log | tail -2
echo done

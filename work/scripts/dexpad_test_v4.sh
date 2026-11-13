#!/system/bin/sh
# L3 center cursor, then X+LB (right swipe) and X+RB (left swipe)
echo "== L3 center =="
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -1
dumpsys input 2>/dev/null | grep -o 'hoveringPointers=[^]]*]' | head -1

echo "== X + LB (right swipe) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 310 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe|deferred|wheel' | tail -5
grep SWIPE /data/adb/gpm/helper.log | tail -1

echo "== X + RB (left swipe) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 311 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe|deferred|wheel' | tail -5
grep SWIPE /data/adb/gpm/helper.log | tail -1
echo done

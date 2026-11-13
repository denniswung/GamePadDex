#!/system/bin/sh
echo "== X + LB (left) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 310 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe' | tail -3
grep SWIPE /data/adb/gpm/helper.log | tail -1

echo "== X + RB (right) =="
logcat -c
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 311 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d -s DexPad 2>/dev/null | grep -E 'mix |swipe' | tail -3
grep SWIPE /data/adb/gpm/helper.log | tail -1

echo "== START (alt+tab) =="
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "top before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 2
echo "top after: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -d 2>/dev/null | grep -E 'key combo|KCOMBO' | tail -3
grep KCOMBO /data/adb/gpm/helper.log | tail -2

#!/system/bin/sh
# smoke test of the released v1.2 install: L3 center, X+LB, START switch
echo "== L3 center =="
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1
sleep 1
grep CENTER /data/adb/gpm/helper.log | tail -1

echo "== X + LB (left) =="
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 310 300 6500 >/dev/null 2>&1
wait
sleep 1
logcat -d 2>/dev/null | grep -E 'mix 4|swipe' | tail -2

echo "== START switch =="
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "top before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "top after: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

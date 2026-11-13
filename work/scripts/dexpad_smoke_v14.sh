#!/system/bin/sh
echo "== v1.4 maximize =="
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
am task resize $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed -n 's/.* t\([0-9]*\)}.*/\1/p') 1290 300 2300 1200 >/dev/null 2>&1
sleep 1
echo "before: $(dumpsys window windows 2>/dev/null | grep -o 'piliplus.MainActivity, frame=\[Rect([^)]*)\]' | head -1)"
/data/local/tmp/vgpad key 314 300 6000 >/dev/null 2>&1
sleep 1
echo "after:  $(dumpsys window windows 2>/dev/null | grep -o 'piliplus.MainActivity, frame=\[Rect([^)]*)\]' | head -1)"
grep ARRANGE /data/adb/gpm/helper.log | tail -1

echo "== v1.4 START from desktop =="
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
input -d 6 keyevent 3
sleep 2
echo "desktop: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "after:   $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

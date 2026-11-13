#!/system/bin/sh
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
echo "== tasks on display 0 =="
am stack list 2>/dev/null | grep -E 'displayId=0' -A6 | grep -o 'taskId=[0-9]*: [^ ]*' | head -6
echo "== tasks on display 6 =="
am stack list 2>/dev/null | grep -E 'displayId=6' -A6 | grep -o 'taskId=[0-9]*: [^ ]*' | head -6
echo "== START from DeX ConfigActivity =="
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "after: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

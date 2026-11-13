#!/system/bin/sh
echo "== maximize via SELECT =="
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "before: $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
/data/local/tmp/vgpad key 314 300 6000 >/dev/null 2>&1
sleep 1
echo "after: $(dumpsys window windows 2>/dev/null | grep -o 'ConfigActivity, frame=\[Rect([^)]*)\]' | head -1)"
grep ARRANGE /data/adb/gpm/helper.log | tail -1

echo "== snap left via action? skip; test START filtering =="
# put a phone-only app on display 0 (not on the DeX display)
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "phone top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "dex apps now:"
am stack list 2>/dev/null | grep -A4 'displayId=6' | grep -o 'taskId=[0-9]*: [^ ]*' | head -6
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "after START: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

#!/system/bin/sh
echo "== START alt+tab =="
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "top before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 2
echo "top after 1: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 2
echo "top after 2: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -d 2>/dev/null | grep -E 'alt\+tab|ALTTAB' | tail -3
grep ALTTAB /data/adb/gpm/helper.log | tail -2

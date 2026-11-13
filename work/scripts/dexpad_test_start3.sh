#!/system/bin/sh
# build recents, go home (desktop), then press START
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
input -d 6 keyevent 3
sleep 2
echo "desktop top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
echo "recents: $(dumpsys activity recents 2>/dev/null | grep -m3 'mActivityComponent=' | tr -d ' ')"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "after START: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

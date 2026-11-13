#!/system/bin/sh
echo "== maximize on a fresh window (PiliPlus on DeX) =="
am start --display 6 -n com.example.piliplus/.MainActivity >/dev/null 2>&1
sleep 2
echo "before: $(dumpsys window windows 2>/dev/null | grep -o 'piliplus.MainActivity, frame=\[Rect([^)]*)\]' | head -1)"
/data/local/tmp/vgpad key 314 300 6000 >/dev/null 2>&1
sleep 1
echo "after:  $(dumpsys window windows 2>/dev/null | grep -o 'piliplus.MainActivity, frame=\[Rect([^)]*)\]' | head -1)"
grep ARRANGE /data/adb/gpm/helper.log | tail -1

echo "== START must stay on DeX apps (phone-only Settings) =="
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "phone top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
# make the DeX app focused again
am start --display 6 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
echo "dex top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
/data/local/tmp/vgpad key 315 300 6000 >/dev/null 2>&1
sleep 3
echo "after START: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

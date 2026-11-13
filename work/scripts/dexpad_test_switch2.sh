#!/system/bin/sh
am start --display 6 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "base: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad double 307 60 90 2600 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad 2>/dev/null | grep -E 'double|switch' | tail -3
echo "after1: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1
echo "== again =="
logcat -c
/data/local/tmp/vgpad double 307 60 90 2600 >/dev/null 2>&1
sleep 2
logcat -d -s DexPad 2>/dev/null | grep -E 'double|switch' | tail -3
echo "after2: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
grep SWITCH /data/adb/gpm/helper.log | tail -1

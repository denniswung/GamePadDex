#!/system/bin/sh
echo "top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad stick 4 20000 800 2600 >/dev/null 2>&1
sleep 2
screencap -p -d 4632669078734337540 /sdcard/v1.png
sleep 2
screencap -p -d 4632669078734337540 /sdcard/v2.png
logcat -d -s DexPad 2>/dev/null | grep -E 'vswipe' | tail -2
grep SWIPE /data/adb/gpm/helper.log | tail -2
ls -l /sdcard/v1.png /sdcard/v2.png | awk '{print $5}'

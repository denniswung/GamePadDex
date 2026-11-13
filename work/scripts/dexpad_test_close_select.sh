#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
echo "top before: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"
logcat -c
/data/local/tmp/vgpad key 314 200 3000 >/dev/null 2>&1
sleep 2
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -E 'button select|close app|close' | tail -3
echo "== helper =="
tail -n 6 /data/adb/gpm/helper.log
echo "top after: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)"

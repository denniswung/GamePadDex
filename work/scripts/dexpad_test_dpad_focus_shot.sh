#!/system/bin/sh
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
input keyevent KEYCODE_WAKEUP
sleep 1
screencap -p /sdcard/f_before.png
/data/local/tmp/vgpad hat 0 1 600 2600 >/dev/null 2>&1
sleep 1
screencap -p /sdcard/f_after.png
ls -l /sdcard/f_before.png /sdcard/f_after.png | awk '{print $5, $8}'

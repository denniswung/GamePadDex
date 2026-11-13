#!/system/bin/sh
D=4630946213010294403
am start --display 3 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
screencap -p -d $D /sdcard/c_before.png
/data/local/tmp/vgpad hat 0 1 600 2600 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/c_after.png
ls -l /sdcard/c_before.png /sdcard/c_after.png | awk '{print $5, $8}'

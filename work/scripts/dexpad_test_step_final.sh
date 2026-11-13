#!/system/bin/sh
D=4630946213010294403
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
screencap -p -d $D /sdcard/e_before.png
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/e_after.png
ls -l /sdcard/e_before.png /sdcard/e_after.png | awk '{print $5, $8}'

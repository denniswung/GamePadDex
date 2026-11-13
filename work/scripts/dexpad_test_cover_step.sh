#!/system/bin/sh
D=4630946213010294403
am force-stop com.android.settings
sleep 1
am start --display 3 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
screencap -p -d $D /sdcard/d_before.png
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/d_after.png
ls -l /sdcard/d_before.png /sdcard/d_after.png | awk '{print $5, $8}'

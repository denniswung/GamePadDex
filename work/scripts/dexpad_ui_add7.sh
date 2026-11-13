#!/system/bin/sh
input tap 450 1094
sleep 1
uiautomator dump /sdcard/ui_after.xml >/dev/null 2>&1
screencap -p -d 4630946213010294403 /sdcard/btn_x3.png
echo done

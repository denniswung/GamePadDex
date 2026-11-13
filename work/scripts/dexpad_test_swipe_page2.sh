#!/system/bin/sh
input -d 6 keyevent KEYCODE_WAKEUP
input -d 6 keyevent KEYCODE_MENU
sleep 1
screencap -p -d 4630946213010294403 /sdcard/p1.png
/data/local/tmp/vgpad key 307 3000 6000 >/dev/null 2>&1 &
sleep 0.2
/data/local/tmp/vgpad key 311 300 6500 >/dev/null 2>&1
wait
sleep 1
screencap -p -d 4630946213010294403 /sdcard/p2.png
sleep 1
screencap -p -d 4630946213010294403 /sdcard/p3.png
ls -l /sdcard/p1.png /sdcard/p2.png /sdcard/p3.png

#!/system/bin/sh
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
D=4630946474867211650
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
timeout 5 "$G" "$CTL" j >/dev/null 2>&1
sleep 0.4
timeout 5 "$G" "$CTL" P 1280 800 2560 1600 >/dev/null 2>&1
sleep 1.0
screencap -p -d $D /sdcard/t71y_a.png
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.2
screencap -p -d $D /sdcard/t71y_b.png
input swipe 1280 900 1280 400 350
sleep 1.2
screencap -p -d $D /sdcard/t71y_c.png
ls -l /sdcard/t71y_*.png

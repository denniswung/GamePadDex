#!/system/bin/sh
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
timeout 5 "$G" "$CTL" j >/dev/null 2>&1
sleep 0.4
timeout 5 "$G" "$CTL" P 1280 800 2560 1600 >/dev/null 2>&1
sleep 1.0
screencap -p -d 0 /sdcard/t71x_a.png
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.2
screencap -p -d 0 /sdcard/t71x_b.png
input swipe 1280 900 1280 400 350
sleep 1.2
screencap -p -d 0 /sdcard/t71x_c.png
echo "shots: $(ls -l /sdcard/t71x_*.png | wc -l)"

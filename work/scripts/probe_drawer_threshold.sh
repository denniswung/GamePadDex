#!/system/bin/sh
# find the shortest fast swipe that actually opens the Lawnchair drawer
D=0
input keyevent KEYCODE_WAKEUP
for dy in 250 350 450 550 650; do
    input keyevent KEYCODE_HOME
    sleep 1
    input keyevent KEYCODE_BACK
    sleep 1
    input swipe 640 1150 640 $((1150-dy)) 100
    sleep 1
    screencap -p /sdcard/t_$dy.png
    sz=$(ls -l /sdcard/t_$dy.png | awk '{print $5}')
    echo "dy=$dy size=$sz"
done

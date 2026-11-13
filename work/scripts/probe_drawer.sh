#!/system/bin/sh
sh /data/local/tmp/dexpad_precondition.sh || exit 2
# objective drawer test: home screenshot size vs after swipe-up
input keyevent KEYCODE_WAKEUP
input keyevent KEYCODE_HOME
sleep 2
screencap -p /sdcard/d_home.png
s1=$(ls -l /sdcard/d_home.png | awk '{print $5}')
/data/local/tmp/vgpad stick 4 20000 700 3000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/d_after.png
s2=$(ls -l /sdcard/d_after.png | awk '{print $5}')
echo "home=$s1 after=$s2"
if [ "$s2" -lt 800000 ]; then echo "PASS drawer opened"; else echo "FAIL drawer not opened"; fi

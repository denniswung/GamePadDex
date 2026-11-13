#!/system/bin/sh
sh /data/local/tmp/dexpad_precondition.sh || exit 2
input keyevent KEYCODE_HOME
sleep 3
grep 'TOP ' /data/adb/gpm/helper.log | tail -1
screencap -p /sdcard/h1.png
s1=$(ls -l /sdcard/h1.png | awk '{print $5}')
L=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 700 3000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/h2.png
s2=$(ls -l /sdcard/h2.png | awk '{print $5}')
echo "home=$s1 after=$s2"
tail -n +$((L + 1)) /data/adb/gpm/helper.log | grep 'SWIPE ' | head -3

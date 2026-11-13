#!/system/bin/sh
D=4630946213010294403
input keyevent KEYCODE_WAKEUP
am force-stop com.android.settings
sleep 1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
screencap -p -d $D /sdcard/a1.png
logcat -c
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/a2.png
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 2
screencap -p -d $D /sdcard/a3.png
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -E 'native navigation|DPAD_CENTER|left button' | tail -4
ls -l /sdcard/a1.png /sdcard/a2.png /sdcard/a3.png | awk '{print $5, $8}'

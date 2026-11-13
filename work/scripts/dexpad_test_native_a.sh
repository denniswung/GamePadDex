#!/system/bin/sh
D=4630946213010294403
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
screencap -p -d $D /sdcard/n1.png
logcat -c
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/n2.png
/data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
sleep 2
screencap -p -d $D /sdcard/n3.png
echo "== engine logs =="
logcat -d -s DexPad 2>/dev/null | grep -E 'native navigation|DPAD_CENTER|left button down' | tail -4
echo "== helper tail =="
tail -n 4 /data/adb/gpm/helper.log
ls -l /sdcard/n1.png /sdcard/n2.png /sdcard/n3.png | awk '{print $5, $8}'

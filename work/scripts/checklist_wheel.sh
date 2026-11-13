#!/system/bin/sh
D=4630946213010294403
input keyevent KEYCODE_WAKEUP
svc power stayon true >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
screencap -p -d $D /sdcard/x1.png
/data/local/tmp/vgpad key 310 1200 3000 >/dev/null 2>&1
sleep 1
screencap -p -d $D /sdcard/x2.png
echo "B4 wheel(Settings): $(ls -l /sdcard/x1.png /sdcard/x2.png | awk '{print $5, $8}' | tr '\n' ' ')"
svc power stayon false >/dev/null 2>&1

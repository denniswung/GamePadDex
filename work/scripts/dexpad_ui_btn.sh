#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
wm dismiss-keyguard
am start --display 0 -n com.dennis.dexpad/.ButtonDetailActivity --es button x >/dev/null 2>&1
sleep 2
screencap -p -d 4630946213010294403 /sdcard/btn_x2.png
uiautomator dump /sdcard/ui_btn.xml >/dev/null 2>&1
echo done

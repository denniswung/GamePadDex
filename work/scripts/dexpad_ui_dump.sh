#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
wm dismiss-keyguard
am start --display 0 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
echo dumped

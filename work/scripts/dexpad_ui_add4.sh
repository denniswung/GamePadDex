#!/system/bin/sh
input tap 450 1880
sleep 1
uiautomator dump /sdcard/ui_s1.xml >/dev/null 2>&1
input tap 450 590
sleep 0.6
uiautomator dump /sdcard/ui_s2.xml >/dev/null 2>&1
echo done

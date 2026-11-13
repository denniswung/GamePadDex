#!/system/bin/sh
input tap 520 2066
sleep 1
input tap 450 1880
sleep 1
uiautomator dump /sdcard/ui_add.xml >/dev/null 2>&1
echo done

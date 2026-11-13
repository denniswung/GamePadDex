#!/system/bin/sh
input tap 722 2066
sleep 1
uiautomator dump /sdcard/ui_act2.xml >/dev/null 2>&1
echo done

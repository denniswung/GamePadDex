#!/system/bin/sh
input tap 450 590
sleep 0.5
input tap 722 2066
sleep 1
uiautomator dump /sdcard/ui_act.xml >/dev/null 2>&1
echo done

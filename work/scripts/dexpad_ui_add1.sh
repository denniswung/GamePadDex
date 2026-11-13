#!/system/bin/sh
input tap 450 1628
sleep 1
uiautomator dump /sdcard/ui_dlg.xml >/dev/null 2>&1
echo tapped

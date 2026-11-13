#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
i=0
while [ $i -lt 3 ]; do
    input swipe 450 500 450 1800 300
    sleep 0.8
    i=$((i+1))
done
uiautomator dump /sdcard/ui3.xml >/dev/null 2>&1
echo dumped

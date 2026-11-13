#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
wm dismiss-keyguard
am start --display 0 -n com.dennis.dexpad/.ConfigActivity >/dev/null 2>&1
sleep 2
i=0
while [ $i -lt 5 ]; do
    input swipe 450 1800 450 500 300
    sleep 0.8
    i=$((i+1))
done
uiautomator dump /sdcard/ui2.xml >/dev/null 2>&1
echo dumped

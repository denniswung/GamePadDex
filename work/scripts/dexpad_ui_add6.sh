#!/system/bin/sh
input keyevent KEYCODE_WAKEUP
am start --display 0 -n com.dennis.dexpad/.ButtonDetailActivity --es button x >/dev/null 2>&1
sleep 2
# open "添加组合" row (device px)
input tap 450 1880
sleep 1
# select Y
input tap 450 590
sleep 0.6
# 下一步
input tap 722 2066
sleep 1
uiautomator dump /sdcard/ui_act3.xml >/dev/null 2>&1
echo done

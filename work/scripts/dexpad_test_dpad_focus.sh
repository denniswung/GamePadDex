#!/system/bin/sh
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
input keyevent KEYCODE_WAKEUP
sleep 1
uiautomator dump /sdcard/ui1.xml >/dev/null 2>&1
A=$(grep -o 'focused="true"[^>]*text="[^"]*"' /sdcard/ui1.xml | head -1)
/data/local/tmp/vgpad hat 0 1 500 2600 >/dev/null 2>&1
sleep 1
uiautomator dump /sdcard/ui2.xml >/dev/null 2>&1
B=$(grep -o 'focused="true"[^>]*text="[^"]*"' /sdcard/ui2.xml | head -1)
echo "before: $A"
echo "after : $B"
if [ "$A" != "$B" ]; then echo "FOCUS CHANGED"; else echo "focus unchanged"; fi

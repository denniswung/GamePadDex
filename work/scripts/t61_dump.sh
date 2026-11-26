#!/system/bin/sh
PAD=com.dennis.padtest
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
uiautomator dump /sdcard/t61.xml >/dev/null 2>&1
echo "== texts =="
grep -a -o 'text="[^"]*"' /sdcard/t61.xml | head -40
echo "== ScrollView/bounds =="
grep -a -o 'scrollable="true"[^>]*bounds="[^"]*"' /sdcard/t61.xml | head -6

am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
rm -f /sdcard/q1.xml
timeout 20 uiautomator dump /sdcard/q1.xml 2>&1 | tail -1
echo "immediate size=$(stat -c %s /sdcard/q1.xml 2>/dev/null)"
sleep 10
rm -f /sdcard/q2.xml
timeout 20 uiautomator dump /sdcard/q2.xml 2>&1 | tail -1
echo "after 10s idle size=$(stat -c %s /sdcard/q2.xml 2>/dev/null)"
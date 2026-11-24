#!/system/bin/sh
# debug uiautomator dump
rm -f /sdcard/t1.xml
timeout 15 uiautomator dump /sdcard/t1.xml
echo "rc=$?"
ls -l /sdcard/t1.xml 2>&1
echo "--- first 200 ---"
head -c 200 /sdcard/t1.xml 2>/dev/null
echo
echo "页 count: $(grep -c '第 1 页' /sdcard/t1.xml 2>/dev/null)"
echo "top: $(dumpsys activity activities | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"
echo "--- compressed variant ---"
timeout 15 uiautomator dump --compressed /sdcard/t2.xml
echo "rc2=$?"
echo "页2 count: $(grep -c '第 1 页' /sdcard/t2.xml 2>/dev/null)"

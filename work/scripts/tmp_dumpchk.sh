am force-stop com.dennis.padtest
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse
sleep 0.5
rm -f /sdcard/y.xml /sdcard/y.lines
timeout 15 uiautomator dump /sdcard/y.xml
echo "dump rc=$? size=$(stat -c %s /sdcard/y.xml 2>/dev/null)"
sed 's/></>\n</g' /sdcard/y.xml > /sdcard/y.lines 2>/dev/null
echo "lines=$(wc -l < /sdcard/y.lines)"
grep -ac '第 ' /sdcard/y.lines
grep -m3 '第 ' /sdcard/y.lines | cut -c1-160
echo "focus: $(dumpsys window | grep -m1 'mCurrentFocus=Window')"
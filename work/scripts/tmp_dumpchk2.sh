am force-stop com.dennis.padtest
cmd statusbar collapse >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
for i in 1 2 3; do
  rm -f /sdcard/z.xml
  timeout 20 uiautomator dump --compressed /sdcard/z.xml 2>&1 | tail -1
  s=$(stat -c %s /sdcard/z.xml 2>/dev/null); echo "try$i size=$s"
  [ -n "$s" ] && [ "$s" -gt 1000 ] && break
  sleep 1.5
done
sed 's/></>\n</g' /sdcard/z.xml > /sdcard/z.lines 2>/dev/null
echo "lines=$(wc -l < /sdcard/z.lines) 第count=$(grep -ac '第 ' /sdcard/z.lines)"
grep -m2 '第 ' /sdcard/z.lines | cut -c1-150
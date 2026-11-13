#!/system/bin/sh
P=com.dennis.padtest
am start -n $P/.ui.LogActivity >/dev/null 2>&1
sleep 1.5
rm -f /data/local/tmp/pt.xml
uiautomator dump --compressed /data/local/tmp/pt.xml 2>&1 | tail -2
echo "--- texts ---"
tr '>' '\n' < /data/local/tmp/pt.xml 2>/dev/null | grep 'text=' | head -12

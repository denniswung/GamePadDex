#!/system/bin/sh
rm -f /data/local/tmp/y.xml /data/local/tmp/y.log
(setsid su -M -c 'id; /system/bin/uiautomator dump --compressed /data/local/tmp/y.xml; echo rc=$?; ls -l /data/local/tmp/y.xml' </dev/null >/data/local/tmp/y.log 2>&1 &)
sleep 4
echo "--- y.log ---"
cat /data/local/tmp/y.log 2>/dev/null
echo "--- y.xml ---"
ls -l /data/local/tmp/y.xml 2>&1

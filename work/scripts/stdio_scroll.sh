#!/system/bin/sh
chmod 755 /data/local/tmp/vgpad
rm -f /data/local/tmp/h2.out
( sleep 10 | /data/adb/gpm/gpminput > /data/local/tmp/h2.out 2>&1 ) &
sleep 2.5
/data/local/tmp/vgpad stick 14 30000 800 1200 >/dev/null 2>&1
sleep 1
/data/local/tmp/vgpad stick 11 30000 800 1200 >/dev/null 2>&1
sleep 2
echo "=== helper output ==="
cat /data/local/tmp/h2.out

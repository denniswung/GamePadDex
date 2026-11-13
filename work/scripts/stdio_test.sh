#!/system/bin/sh
pkill -f "stdio-test" 2>/dev/null
sleep 0.3
rm -f /data/local/tmp/h.out
( sleep 12 | /data/adb/gpm/gpminput > /data/local/tmp/h.out 2>&1 ) &
sleep 2.5
chmod 755 /data/local/tmp/vgpad
/data/local/tmp/vgpad key 304 120 1500 >/dev/null 2>&1
sleep 2
echo "=== helper stdio output ==="
cat /data/local/tmp/h.out
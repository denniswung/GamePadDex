#!/system/bin/sh
echo "pads: $(grep -c 'Virtual Dpad' /proc/bus/input/devices)"
L1=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad hat 0 1 600 2600 >/dev/null 2>&1
sleep 1
L2=$(wc -l < /data/adb/gpm/helper.log)
echo "lines $L1 -> $L2"
tail -n 12 /data/adb/gpm/helper.log

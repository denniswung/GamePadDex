#!/system/bin/sh
NODE=$(awk '/Virtual Dpad/{f=1} f&&/Handlers=/{match($0,/event[0-9]+/); print "/dev/input/" substr($0,RSTART,RLENGTH); exit}' /proc/bus/input/devices)
echo "node: $NODE"
rm -f /data/local/tmp/ev3.txt
( getevent "$NODE" > /data/local/tmp/ev3.txt 2>&1 ) &
GP=$!
sleep 0.5
/data/local/tmp/vgpad hat 0 1 800 2600 >/dev/null 2>&1
sleep 1
kill $GP 2>/dev/null
echo "== events =="
cat /data/local/tmp/ev3.txt

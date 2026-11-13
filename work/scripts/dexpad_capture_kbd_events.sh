#!/system/bin/sh
NODE=$(awk '/Gamepad Mouse Keyboard/{f=1} f&&/Handlers=/{print; exit}' /proc/bus/input/devices)
echo "handlers: $NODE"
DEV=$(echo "$NODE" | sed -n 's/.*\(event[0-9]*\).*/\1/p')
echo "dev: /dev/input/$DEV"
rm -f /data/local/tmp/ev_kbd.txt
( getevent "/dev/input/$DEV" > /data/local/tmp/ev_kbd.txt 2>&1 ) &
GP=$!
sleep 0.5
/data/local/tmp/vgpad hat 0 1 800 2600 >/dev/null 2>&1
sleep 1
kill $GP 2>/dev/null
echo "== keyboard events =="
cat /data/local/tmp/ev_kbd.txt

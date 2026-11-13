#!/system/bin/sh
NODE=""
for d in /sys/class/input/event*/device/name; do
    if grep -q 'Virtual Dpad' "$d" 2>/dev/null; then
        NODE=/dev/input/$(echo "$d" | sed 's#/sys/class/input/##; s#/device/name##')
        break
    fi
done
echo "node: $NODE"
rm -f /data/local/tmp/dpad_ev.txt
( timeout 6 getevent -l "$NODE" > /data/local/tmp/dpad_ev.txt 2>&1 ) &
sleep 1
logcat -c
/data/local/tmp/vgpad hat 0 1 600 2600 >/dev/null 2>&1
sleep 2
echo "== virtual dpad events =="
cat /data/local/tmp/dpad_ev.txt
echo "== engine =="
logcat -d -s DexPad 2>/dev/null | grep -E 'arrow key|dpad native' | tail -3
echo "== helper raw hat/key lines =="
grep -E 'AX 0 1[56]|KEY 0 54[4-7]' /data/adb/gpm/helper.log | tail -3

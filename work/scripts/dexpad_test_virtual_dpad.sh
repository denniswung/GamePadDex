#!/system/bin/sh
# find the virtual dpad event node
NODE=""
for d in /sys/class/input/event*/device/name; do
    if grep -q 'Virtual Dpad' "$d" 2>/dev/null; then
        NODE=/dev/input/$(echo "$d" | sed 's#/sys/class/input/##; s#/device/name##')
        break
    fi
done
echo "node: $NODE"
am start --display 0 -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
logcat -c
( timeout 4 getevent -l "$NODE" > /data/local/tmp/dpad_ev.txt 2>&1 ) &
GPID=$!
sleep 0.5
/data/local/tmp/vgpad hat 0 1 800 2600 >/dev/null 2>&1
wait $GPID
echo "== getevent on virtual dpad =="
cat /data/local/tmp/dpad_ev.txt
echo "== engine logs =="
logcat -d -s DexPad 2>/dev/null | grep -E 'arrow key|dpad native' | tail -3
echo "== helper AX(hat)/KEY for dpad =="
grep -E 'AX .* 1[56] |KEY .* (544|545|546|547)' /data/adb/gpm/helper.log | tail -3

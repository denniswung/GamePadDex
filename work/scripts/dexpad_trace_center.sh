#!/system/bin/sh
# press L3 and sample the pointer position for ~2.5 s to see any post-center jump
/data/local/tmp/vgpad key 317 300 6000 >/dev/null 2>&1 &
sleep 5.4
for i in $(seq 1 16); do
    P=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
    echo "$i: $P"
    sleep 0.15
done
echo "== center log =="
grep CENTER /data/adb/gpm/helper.log | tail -4
echo "== engine pointer moves =="
logcat -d -s DexPad 2>/dev/null | grep -E 'cursor centered' | tail -2

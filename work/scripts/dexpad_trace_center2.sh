#!/system/bin/sh
# hold the left stick deflected, press L3 mid-way, and watch the pointer
/data/local/tmp/vgpad stick 0 20000 3000 6000 >/dev/null 2>&1 &
sleep 0.1
/data/local/tmp/vgpad key 317 300 6300 >/dev/null 2>&1 &
sleep 7.0
echo "== while stick still deflected (after L3) =="
for i in 1 2 3 4 5 6; do
    echo "$i: $(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)"
    sleep 0.2
done
sleep 2
echo "== after stick released =="
for i in 1 2 3 4; do
    echo "$i: $(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)"
    sleep 0.2
done
echo "== center log =="
grep CENTER /data/adb/gpm/helper.log | tail -2

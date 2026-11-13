#!/system/bin/sh
am broadcast -a com.dennis.dexpad.V2 -n com.dennis.dexpad/.DebugReceiver --el center_lock_ms 5000 >/dev/null 2>&1
am start -n com.dennis.dexpad/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
ok=0
for i in 1 2 3; do
    L=$(wc -l < /data/adb/gpm/helper.log)
    /data/local/tmp/vgpad key 317 100 3000 >/dev/null 2>&1
    sleep 0.2
    if tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -q CENTER; then ok=1; break; fi
done
echo "center seen=$ok"
P0=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
/data/local/tmp/vgpad stick 0 20000 300 3000 >/dev/null 2>&1
sleep 0.2
P1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
echo "P0=$P0 P1=$P1"

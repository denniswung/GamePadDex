#!/system/bin/sh
P=com.dennis.padtest
VG=/data/local/tmp/vgpad
am start -n $P/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5
for pre in 0 5 15 30 60; do
    logcat -c
    L=$(wc -l < /data/adb/gpm/helper.log)
    $VG key 308 120 $pre >/dev/null 2>&1
    sleep 0.9
    K=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')
    SEEN=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEY 0 308 1')
    UP=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEY 0 308 0')
    echo "pre=${pre}ms  down_seen=$SEEN up_seen=$UP home=$K"
    logcat -d -s DexPad | grep -E 'button y|single home|home on display' | sed 's/^.*DexPad  : /    /' | head -3
done

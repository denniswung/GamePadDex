#!/system/bin/sh
VG=/data/local/tmp/vgpad
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5
for v in 6000 12000 20000; do
    logcat -c
    L=$(wc -l < /data/adb/gpm/helper.log)
    $VG holdstick 308 0 $v 700 2000 >/dev/null 2>&1
    sleep 1.2
    echo "stick=$v  home=$(tail -n +$((L+1)) /data/adb/gpm/helper.log | grep -c 'KEYON 0 3')"
    logcat -d -s DexPad | grep -E 'button y|single|home|cancel' | sed 's/^.*DexPad  : /    /'
done

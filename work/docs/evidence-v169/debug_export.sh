#!/system/bin/sh
# debug: padtest v1.4 report export path + METRICS log
am force-stop com.dennis.padtest >/dev/null 2>&1
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.5
logcat -c
am broadcast -a com.dennis.padtest.EXPORT -n com.dennis.padtest/.core.ExportReceiver --es what report --es fmt json >/dev/null 2>&1
sleep 1.5
echo "=== METRICS/logcat ==="
logcat -d | grep -aE 'METRICS|EXPORT|export' | tail -5
echo "=== files under app external ==="
ls -l /sdcard/Android/data/com.dennis.padtest/files/ 2>&1 | tail -10
echo "=== files under /data/local/tmp (recent) ==="
ls -lt /data/local/tmp/*.json 2>/dev/null | head -5
echo "=== files dir ==="
ls -l /data/data/com.dennis.padtest/files/ 2>&1 | tail -10

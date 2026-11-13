#!/system/bin/sh
# trigger the KernelSU service stage and verify the helper/engine come up
logcat -c
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do
    kill -9 "$p"
done
sleep 1
/data/adb/ksud services
sleep 8
echo "== procs =="
ps -A -o PID,PPID,NAME | grep -E 'gpminput|gpm_dex' | grep -v grep
echo "== helper log =="
tail -6 /data/adb/gpm/helper.log
echo "== module log =="
tail -8 /data/local/tmp/gpm-module.log
echo "== engine log =="
logcat -d -s DexPad -s DexPadLink 2>/dev/null | tail -18

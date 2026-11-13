#!/system/bin/sh
# restart the helper through the KernelSU service stage (simulates boot)
pkill -f 'gpm_dex/service.sh --supervisor' 2>/dev/null
sleep 1
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do
    kill -9 "$p"
done
sleep 1
/data/adb/ksud services
sleep 10
echo "== procs =="
ps -A -o PID,PPID,NAME,ARGS | grep -E 'gpminput|gpm_dex' | grep -v grep
echo "== helper log =="
tail -3 /data/adb/gpm/helper.log
echo "== engine log =="
logcat -d -s DexPad -s DexPadLink 2>/dev/null | tail -5

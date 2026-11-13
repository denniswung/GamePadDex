#!/system/bin/sh
sh /data/adb/modules/zygisk_vector/action.sh >/dev/null 2>&1
sleep 8
L=$(ls -t /data/adb/lspd/log/verbose_*.log 2>/dev/null | sed -n 1p)
echo "log=$L"
echo "daemon-not-active count: $(grep -c 'Daemon is not active' "$L" 2>/dev/null)"
echo "=== manager lines ==="
grep -E 'VectorManager' "$L" 2>/dev/null | tail -8
echo "=== db ==="
ls -l /data/adb/lspd/config/

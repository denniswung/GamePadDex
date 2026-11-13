#!/system/bin/sh
echo "== vector procs =="
ps -A -o PID,NAME | grep -iE 'vectord|vector.manager' | grep -v grep
echo "== open manager via module action =="
sh /data/adb/modules/zygisk_vector/action.sh 2>&1 | tail -2
sleep 10
L=$(ls -t /data/adb/lspd/log/verbose_*.log 2>/dev/null | sed -n 1p)
echo "== log: $L =="
echo "errors:"; grep -E 'E/Vector|Daemon is not active|Parasitic' "$L" 2>/dev/null | tail -8
echo "manager lines:"; grep -E 'VectorManager' "$L" 2>/dev/null | tail -10
echo "== modules from db =="
ls -l /data/adb/lspd/config/modules_config.db* 2>/dev/null

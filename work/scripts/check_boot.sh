#!/system/bin/sh
PKG=com.dennis.gamepadmouse
B=$(wc -l < /data/local/tmp/gpm-module.log 2>/dev/null || echo 0)
sleep 6
A=$(wc -l < /data/local/tmp/gpm-module.log 2>/dev/null || echo 0)
echo "log_lines_before=$B after=$A  (growing means the churn is still alive)"
echo "--- supervisors ---"
ps -A -o PID,ARGS 2>/dev/null | grep -E 'gpm_dex/service.sh|99-gpm' | grep -v grep
echo "--- helpers ---"
ps -A -o PID,NAME | grep gpminput | grep -v grep
echo "--- app connection ---"
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected to helper|helper ready|grabbed|ERR" | tail -4

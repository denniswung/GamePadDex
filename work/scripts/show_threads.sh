#!/system/bin/sh
PID=$(pidof com.dennis.dexpad | awk '{print $1}')
echo "pid=$PID"
cat /proc/$PID/task/*/comm 2>/dev/null | sort | uniq -c | sort -rn | head -25

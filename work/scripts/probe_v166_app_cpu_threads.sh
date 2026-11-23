#!/system/bin/sh
# 线程级 CPU：引擎 8ms 循环到底花在哪
PID=$(pidof com.dennis.dexpad)
echo "pid=$PID"
top -b -n 1 -H -p "$PID" 2>/dev/null | head -20
echo "--- thread ticks (10s delta) ---"
for t in /proc/$PID/task/*; do
  n=$(cat "$t/comm" 2>/dev/null)
  u=$(awk '{print $14+$15}' "$t/stat" 2>/dev/null)
  echo "$u $n"
done | sort -rn | head -10
sleep 10
echo "--- after 10s ---"
for t in /proc/$PID/task/*; do
  n=$(cat "$t/comm" 2>/dev/null)
  u=$(awk '{print $14+$15}' "$t/stat" 2>/dev/null)
  echo "$u $n"
done | sort -rn | head -10

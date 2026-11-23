#!/system/bin/sh
PID=$(pidof com.dennis.dexpad)
echo "pid=$PID"
snap(){
  for t in /proc/$PID/task/*; do
    n=$(cat "$t/comm" 2>/dev/null)
    u=$(awk '{print $14+$15}' "$t/stat" 2>/dev/null)
    echo "$u|$n"
  done | sort -t'|' -k1 -rn | head -12
}
snap > /data/local/tmp/thr0.txt
sleep 30
snap > /data/local/tmp/thr1.txt
echo "--- 30s delta ---"
awk -F'|' 'NR==FNR{a[$2]=$1;next}{d=$1-a[$2]; if(d>0) printf "%4d ticks  %5.2f%%  %s\n", d, d/30.0, $2}' /data/local/tmp/thr0.txt /data/local/tmp/thr1.txt | sort -rn | head -10
awk -F'|' 'NR==FNR{a[$2]=$1;next}{d=$1-a[$2]; if(d>0) s+=d}END{printf "total=%.2f%%\n", s/30.0}' /data/local/tmp/thr0.txt /data/local/tmp/thr1.txt

VG=/data/local/tmp/vgpad
x1(){ logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ I PadProbe: MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1/p' | head -1; }
x2(){ logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ I PadProbe: MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1/p' | tail -1; }
for d in 50 80; do
  $VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
  logcat -c
  $VG stick 0 30000 $d >/dev/null 2>&1; sleep 0.45
  a=$(x1); b=$(x2); echo "d=${d}ms from=$a to=$b dx=$((b-a))"
done
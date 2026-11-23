#!/system/bin/sh
# quick dpi speed probe: from left edge, unclamped 150ms / 200ms full pushes
VG=/data/local/tmp/vgpad
tdx() { logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ I PadProbe: MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1/p' | awk 'NR==1{a=$1} {b=$1} END{print (a==""||b=="")?0:b-a}'; }
t0p() { logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ I PadProbe: MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1/p' | head -1; }
tlp() { logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ I PadProbe: MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1/p' | tail -1; }
echo "== 150ms from left edge =="
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
$VG stick 0 -30000 550 >/dev/null 2>&1; sleep 0.7
logcat -c
$VG stick 0 30000 150 >/dev/null 2>&1; sleep 0.5
echo "  from=$(t0p) to=$(tlp) dx=$(tdx)"
echo "== 200ms from left edge =="
$VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
$VG stick 0 -30000 550 >/dev/null 2>&1; sleep 0.7
logcat -c
$VG stick 0 30000 200 >/dev/null 2>&1; sleep 0.5
echo "  from=$(t0p) to=$(tlp) dx=$(tdx)"
echo "== 100ms from center (L3, twice) =="
for i in 1 2; do
  $VG key 317 100 800 >/dev/null 2>&1; sleep 1.2
  logcat -c
  $VG stick 0 30000 100 >/dev/null 2>&1; sleep 0.5
  echo "  run$i from=$(t0p) to=$(tlp) dx=$(tdx)"
done

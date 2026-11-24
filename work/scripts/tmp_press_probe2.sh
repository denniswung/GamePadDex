VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
HL=/data/adb/gpm/helper.log
PY=0
dump_ui(){ local i=0; while [ $i -lt 3 ]; do i=$((i+1)); rm -f /sdcard/d.xml /sdcard/d.lines 2>/dev/null
  timeout 12 uiautomator dump /sdcard/d.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/d.xml > /sdcard/d.lines 2>/dev/null
  grep -q '第 [1-5] 页' /sdcard/d.lines 2>/dev/null && return 0; sleep 0.5; done; return 1; }
scroll_metrics(){ PY=-1; local n l b y; for n in 1 2 3; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/d.lines 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.3; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
hold_rb(){ $VG key 311 $1 400 >/dev/null 2>&1; }
draglog(){ logcat -d -s DexPad 2>/dev/null | grep -aE 'drag (start|end|re-anchor|stop)'; }
press_py(){ starts; l3
  dump_ui; scroll_metrics; local p0=$PY
  : > "$HL"; logcat -c
  if [ "$1" = "LB" ]; then $VG key 310 "$2" 400 >/dev/null 2>&1; else hold_rb "$2"; fi
  sleep 0.9
  dump_ui; scroll_metrics; local p1=$PY
  local d=$((p0 - p1)); [ "$d" -lt 0 ] && d=$((-d))
  echo "$d|$p1|$(draglog | tail -2 | tr '\n' ';')"
}
echo "== press_py test =="
r=$(press_py RB 500); echo "raw=[$r]"; echo "first=${r%%|*}"
echo "== getevent test =="
NODE=/dev/input/event22
( timeout 1.5 getevent -lt $NODE > /data/local/tmp/ge.txt 2>&1 & )
sleep 0.2
hold_rb 700
sleep 1.0
echo "lines=$(wc -l < /data/local/tmp/ge.txt)"; grep -a 'ABS_MT_POSITION_Y' /data/local/tmp/ge.txt | head -3; echo "count=$(grep -ac 'ABS_MT_POSITION_Y' /data/local/tmp/ge.txt)"
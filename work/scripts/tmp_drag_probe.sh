#!/system/bin/sh
VG=/data/local/tmp/vgpad
PAD=com.dennis.padtest
HL=/data/adb/gpm/helper.log
PY=0
dump_ui(){ local i=0; while [ $i -lt 3 ]; do i=$((i+1)); rm -f /sdcard/x.xml /sdcard/x.lines 2>/dev/null
  timeout 12 uiautomator dump /sdcard/x.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/x.xml > /sdcard/x.lines 2>/dev/null
  grep -q '第 [1-5] 页' /sdcard/x.lines 2>/dev/null && return 0; sleep 0.5; done; return 1; }
py(){ PY=-1; local n l b; for n in 1 2 3; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/x.lines 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; [ "$PY" = "-1" ] && PY=$2; done; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; cmd statusbar collapse >/dev/null 2>&1; sleep 0.3; }
echo "== 3x100ms =="
for i in 1 2 3; do
  starts; $VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
  dump_ui; py; p0=$PY; : > $HL; logcat -c
  $VG key 311 100 400 >/dev/null 2>&1; sleep 1.0
  dump_ui; py; p1=$PY
  echo "  #$i PY $p0->$p1 d=$((p0-p1)) | $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //') | $(grep -a 'DRAG up' $HL | tail -1)"
done
echo "== 3x1000ms =="
for i in 1 2 3; do
  starts; $VG key 317 100 800 >/dev/null 2>&1; sleep 0.8
  dump_ui; py; p0=$PY; : > $HL; logcat -c
  $VG key 311 1000 400 >/dev/null 2>&1; sleep 1.2
  dump_ui; py; p1=$PY
  echo "  #$i PY $p0->$p1 d=$((p0-p1)) | $(logcat -d -s DexPad | grep -a 'drag end' | tail -1 | sed 's/^.*DexPad *: //') | $(grep -a 'DRAG up' $HL | tail -1)"
done

#!/system/bin/sh
# temp diagnostic for A5 (pointer hidden -> first swipe)
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
OUT=/data/local/tmp/a5diag.log
: > "$OUT"
L(){ echo "$@" | tee -a "$OUT"; }
dumpm(){
  timeout 12 uiautomator dump /sdcard/a5.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/a5.xml > /sdcard/a5.lines 2>/dev/null
  PY=-1; HS=0
  local n l b x1 y1 x2 y2 w sx
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/a5.lines 2>/dev/null)
    [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')
    [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2-x1))
    if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
}
pdev(){
  am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "?" >/dev/null 2>&1
  sleep 1.2
  grep -a '^INFO pointer device=' "$HL" 2>/dev/null | tail -1 | sed 's/.*device=//'
}
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.2
cmd statusbar collapse >/dev/null 2>&1
sleep 0.5
L "== variant A: page at top, wait hide, first push DOWN (stick 4 +24000) =="
dumpm; L "  PY before=$PY HS=$HS pdev=$(pdev)"
sleep 9.5
L "  pdev before push=$(pdev)"
: > "$HL"; logcat -c
$VG stick 4 24000 1500 >/dev/null 2>&1
sleep 1.5
dumpm
L "  PY after=$PY HS=$HS"
L "  SWIPE: $(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -3 | tr '\n' '|')"
L "  SWIPE_n=$(grep -ac '^SWIPE ' "$HL")"
L "  PadProbe: $(logcat -d -s PadProbe 2>/dev/null | grep -aE 'TOUCH|MOUSE' | tail -6 | sed 's/^.*PadProbe: //' | tr '\n' '|')"

L ""
L "== variant B: pre-scroll down, wait hide, first push UP (stick 4 -24000) =="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2.2
cmd statusbar collapse >/dev/null 2>&1
# 预滚：向下滚一段（PY 1415 -> 较小）
$VG stick 4 24000 1500 >/dev/null 2>&1
sleep 1.5
dumpm; L "  pre-scroll PY=$PY HS=$HS pdev=$(pdev)"
sleep 9.5
L "  pdev before push=$(pdev)"
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 >/dev/null 2>&1
sleep 1.5
dumpm
L "  PY after=$PY HS=$HS (期望 PY 增大)"
L "  SWIPE: $(grep -a '^SWIPE ' "$HL" 2>/dev/null | head -3 | tr '\n' '|')"
L "  PadProbe: $(logcat -d -s PadProbe 2>/dev/null | grep -aE 'TOUCH|MOUSE' | tail -6 | sed 's/^.*PadProbe: //' | tr '\n' '|')"

#!/system/bin/sh
# v1.66 release probe: (a) left-stick cursor move, (b) vertical scroll sequence variants
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
cxy() { logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
scroll_metrics() {
  timeout 12 uiautomator dump /sdcard/v166_ui.xml >/dev/null 2>&1
  sed 's/></>\n</g' /sdcard/v166_ui.xml > /sdcard/v166_ui.lines 2>/dev/null
  PY=-1; HS=0
  for n in 1 2 3 4; do
    l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v166_ui.lines 2>/dev/null); [ -z "$l" ] && continue
    b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue
    set -- $b; x1=$1; y1=$2; x2=$3
    [ "$PY" = "-1" ] && PY=$y1
    w=$((x2 - x1)); if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600 * (n - 1) + 600 - w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi
  done
}
pickZ() { grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" 'NF==4{k=($1==$3)?"Z":"V"; if(k!=want) next; d=(k=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++} END{printf "%d %d", n+0, s+0}'; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin() { settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }

echo "=== (a) left-stick cursor move (axis 0) ==="
wake; pin
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.4
cmd statusbar collapse >/dev/null 2>&1
$VG key 317 100 0 >/dev/null 2>&1; sleep 1.2
logcat -c
$VG stick 0 30000 300 >/dev/null 2>&1
sleep 0.8
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.6
echo "click_after_move=[$(cxy)]"
logcat -d -s DexPad 2>/dev/null | grep -aiE 'stick|pointer|move' | tail -5

echo "=== (b1) vertical: starts -> dump -> l3 -> 450ms push ==="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.6
cmd statusbar collapse >/dev/null 2>&1
scroll_metrics; p0=$PY h0=$HS
$VG key 317 100 0 >/dev/null 2>&1; sleep 1.2
: > "$HL"; logcat -c
$VG stick 4 24000 450 >/dev/null 2>&1
sleep 1.4
scroll_metrics; echo "b1: PY $p0 -> $PY  HS $h0 -> $HS  Z=[$(pickZ Z)] V=[$(pickZ V)]"
grep -a '^SWIPE ' "$HL" | tail -3

echo "=== (b2) vertical: first push right after start (no L3), 1500ms ==="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.6
cmd statusbar collapse >/dev/null 2>&1
scroll_metrics; p0=$PY
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 >/dev/null 2>&1
sleep 1.4
scroll_metrics; echo "b2: PY $p0 -> $PY Z=[$(pickZ Z)] V=[$(pickZ V)]"
grep -a '^SWIPE ' "$HL" | tail -3
echo "=== dexpad tail ==="
logcat -d -s DexPad 2>/dev/null | tail -12

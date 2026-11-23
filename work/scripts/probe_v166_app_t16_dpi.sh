#!/system/bin/sh
# t16 dpi：把 speed_phone 临时降到 16（48 的 1/3），300ms 满推不撞边，再 ×3 折算 48 的 300ms
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_t16_dpi.log
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
setp(){ am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; sleep 0.8; }
prefsg(){ grep -o "name=\"$1\" value=\"[^\"]*\"" /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.1; }
trail(){ logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ ([0-9:.]+).*MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1 \2 \3/p' | awk '
  { split($1,a,":"); t=a[1]*3600+a[2]*60+a[3]; x=$2+0; y=$3+0;
    if(n==0){fx=x;fy=y;ft=t} lx=x;ly=y;lt=t;n++ }
  END{ if(n<2){print "n=0"} else printf "n=%d dx=%d dy=%d from=%d,%d to=%d,%d", n,lx-fx,ly-fy,fx,fy,lx,ly }'; }
wake
L "=== dpi 非撞边：speed_phone=16 × 300ms 满推（预期 ~840px），再 ×3 折算 48 ==="
L "  before: $(prefsg speed_phone)"
setp --es pref speed_phone --ei ival 16
L "  set: $(prefsg speed_phone)"
startp; cmd statusbar collapse >/dev/null 2>&1
for dir in -30000 30000 -30000; do
  l3
  logcat -c
  $VG stick 0 "$dir" 300 0 >/dev/null 2>&1
  sleep 0.7
  T=$(trail)
  EDGE=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'at app edge')
  A=$(echo "$T" | sed -n 's/.*dx=\(-\{0,1\}[0-9]*\).*/\1/p'); A=${A#-}
  if [ -n "$A" ]; then
    L "  dir=$dir: $T edge_logs=$EDGE => ×3 = $((A*3))px ($(awk -v a="$A" 'BEGIN{printf "%.1f", a*3/25.6}')% 屏宽)"
  else
    L "  dir=$dir: no-trail edge_logs=$EDGE | $T"
  fi
done
setp --es pref speed_phone --ei ival 48
L "  restored: $(prefsg speed_phone)"
L "  verify 48 again:"
l3; logcat -c
$VG stick 0 -30000 300 0 >/dev/null 2>&1; sleep 0.7
L "    $(trail) edge=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'at app edge')"
L DONE

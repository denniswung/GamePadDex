#!/system/bin/sh
# probe_v166_t16_data.sh -- t16 独立测量（不撞边 dpi / L3 端到端延迟 / 滚动 PY-HS / riseCrossMs）
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
HL=/data/adb/gpm/helper.log
LOG=/data/local/tmp/v166_t16_data.log
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2; }
starts(){ am force-stop $PAD >/dev/null 2>&1; am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 2.2; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.2; }
click(){ $VG key 304 60 0 >/dev/null 2>&1; sleep 0.5; }
trail(){ logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ ([0-9:.]+).*MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1 \2 \3/p' | awk '
  { split($1,a,":"); t=a[1]*3600+a[2]*60+a[3]; x=$2+0; y=$3+0;
    if(n==0){fx=x;fy=y;ft=t} lx=x;ly=y;lt=t;n++ }
  END{ if(n<2){printf "n=%d",n} else printf "n=%d from=%d,%d to=%d,%d dt=%.0fms dx=%d dy=%d", n,fx,fy,lx,ly,(lt-ft)*1000,lx-fx,ly-fy }'; }
cxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
picked(){ grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" '
  NF==4 { k=($1==$3)?"Z":"V"; if(k!=want) next; d=(k=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++ }
  END{ printf "%d %d", n+0, s+0 }'; }
scroll_metrics(){ timeout 12 uiautomator dump /sdcard/v166_t16_ui.xml >/dev/null 2>&1; sed 's/></>\n</g' /sdcard/v166_t16_ui.xml > /sdcard/v166_t16_ui.lines 2>/dev/null; PY=-1; HS=0; for n in 1 2 3 4; do l=$(grep -m1 "text=\"第 $n 页\"" /sdcard/v166_t16_ui.lines 2>/dev/null); [ -z "$l" ] && continue; b=$(echo "$l" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'); [ -z "$b" ] && continue; set -- $b; x1=$1; y1=$2; x2=$3; [ "$PY" = "-1" ] && PY=$y1; w=$((x2-x1)); if [ "$w" -gt 0 ] && [ "$w" -lt 600 ]; then sx=$((600*(n-1)+600-w)); [ "$sx" -gt "$HS" ] && HS=$sx; fi; done; }

wake
L "=== 0. 环境 ==="
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  apk_sha=$(sha256sum $(pm path $PKG | sed 's/package://') | cut -d' ' -f1)"
L "  helper_sha=$(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
L "  app=$(dumpsys display 2>/dev/null | grep -m1 mOverrideDisplayInfo | grep -o 'app [0-9]* x [0-9]*' | tail -1) rot=$(dumpsys display 2>/dev/null | grep -m1 mOverrideDisplayInfo | grep -o 'rotation [0-9]')"

L ""
L "=== 1. L3 端到端延迟（按下→CENTER_OK；含 P 事件驱动）==="
startp
cmd statusbar collapse >/dev/null 2>&1
for i in 1 2 3; do
  logcat -c
  $VG key 317 100 0 >/dev/null 2>&1
  sleep 1.6
  OUT=$(logcat -d -v threadtime -s DexPad PadProbe 2>/dev/null | awk '
    /button l3 down/ { split($2,t,":"); if (t0==0) t0=t[1]*3600+t[2]*60+t[3] }
    /L3 POSPTR/ { pos=1 }
    /CENTER_OK/ { split($2,t,":"); if (t0>0) { c=t[1]*3600+t[2]*60+t[3]; took=(c-t0)*1000; line=$0; sub(/^.*DexPad *: /,"",line) } }
    /MOUSE\/hover x=12[0-9][0-9] y=7[0-9][0-9]/ { split($2,t,":"); if (t0>0 && h==0) { h=t[1]*3600+t[2]*60+t[3] } }
    END{ printf "pressToCENTER_OK=%.0fms pressToCenterHover=%.0fms posptr=%d | %s", took, (h>0?(h-t0)*1000:-1), pos+0, line }')
  L "  run$i $(echo "$OUT" | sed 's/|.*//')"
done
L "  last CENTER_OK=$(logcat -d -s DexPad | grep -a 'CENTER_OK' | tail -1 | sed 's/^.*DexPad *: //')"
L "  POSPTR=$(logcat -d -s DexPad | grep -a 'L3 POSPTR' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  fallback=$(logcat -d -s DexPad | grep -a 'L3 fallback' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"

L ""
L "=== 2. dpi：屏幕中心起手 150ms 满推（不撞边）→ 线性折算 300ms ==="
for dir in -30000 30000 -30000 30000; do
  l3
  logcat -c
  $VG stick 0 "$dir" 150 0 >/dev/null 2>&1
  sleep 0.6
  T=$(trail); DX=$(echo "$T" | sed -n 's/.*dx=\(-\{0,1\}[0-9]*\).*/\1/p')
  EDGE=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'at app edge')
  EST=$(logcat -d -s DexPad 2>/dev/null | grep -a 'ptr move' | tail -1 | sed 's/^.*DexPad *: //')
  if [ -n "$DX" ]; then
    A=$(awk -v d="$DX" 'BEGIN{ if(d<0)d=-d; print d }')
    L "  dir=$dir 150ms: $(echo "$T" | sed 's/.* //') edge_logs=$EDGE est=[$EST] => 300ms 线性折算=$((A*2))px ($(awk -v a="$A" 'BEGIN{printf "%.1f", a*2/25.6}')% 屏宽)"
  else
    L "  dir=$dir 150ms: no-trail edge_logs=$EDGE | $T"
  fi
done

L ""
L "=== 3. 独立滚动测量：uiautomator PY/HS 前后差（ScrollTestActivity）==="
starts
cmd statusbar collapse >/dev/null 2>&1
scroll_metrics; P0=$PY; H0=$HS
: > "$HL"
$VG stick 4 -24000 1500 0 >/dev/null 2>&1; sleep 1.0
scroll_metrics; P1=$PY; H1=$HS; DPY=$((P0-P1)); [ "$DPY" -lt 0 ] && DPY=$((-DPY))
Z=$(picked Z)
L "  vertical 1.5s: PY $P0->$P1 (d=$DPY) HS $H0->$H1 | Z=$(echo $Z|cut -d' ' -f1) total=$(echo $Z|cut -d' ' -f2)px"
: > "$HL"
$VG stick 3 24000 1500 0 >/dev/null 2>&1; sleep 1.0
scroll_metrics; P2=$PY; H2=$HS; DHS=$((H2-H1)); [ "$DHS" -lt 0 ] && DHS=$((-DHS))
V=$(picked V)
L "  horizontal 1.5s: PY $P1->$P2 (d=$((P1-P2))) HS $H1->$H2 (d=$DHS) | V=$(echo $V|cut -d' ' -f1) total=$(echo $V|cut -d' ' -f2)px"
L "  clean counts: Z=$(echo $Z|cut -d' ' -f1)/$(echo $Z|cut -d' ' -f2)px V=$(echo $V|cut -d' ' -f1)/$(echo $V|cut -d' ' -f2)px ratio=$(awk -v a="$(echo $V|cut -d' ' -f2)" -v b="$(echo $Z|cut -d' ' -f2)" 'BEGIN{ if(b>0) printf "%.3f", a/b; else print "na" }')"

L ""
L "=== 4. 唤醒 riseCrossMs（快推 vs 慢爬）==="
if pidof vgpad >/dev/null 2>&1; then L "  BUSY vgpad"; else
  startp; $VG stick 0 0 60000 0 >/dev/null 2>&1 & VGPID=$!
  sleep 2.5
  NODE=$(getevent -lp 2>/dev/null | awk '/^add device/{d=$4} /Virtual Test Gamepad/{print d}' | tail -1)
  sendabs(){ sendevent "$1" 3 0 "$2" 2>/dev/null; sendevent "$1" 0 0 0 2>/dev/null; }
  wf(){ dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*mWakefulness=//;s/ .*//'; }
  input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
  logcat -c
  sendabs "$NODE" 30000; sleep 0.9; sendabs "$NODE" 0; sleep 1.6
  L "  fast push: $(logcat -d -s DexPad | grep -aE 'wake riseCross|wake sent' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
  L "  wakefulness=$(wf)"
  input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
  logcat -c
  for v in 8000 14000 20000 24000 27000 29000 30000; do sendabs "$NODE" "$v"; sleep 0.3; done
  sleep 1.2; sendabs "$NODE" 0; sleep 1.2
  L "  slow ramp: $(logcat -d -s DexPad | grep -aE 'wake riseCross|wake sent' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
  L "  wakefulness=$(wf)"
  kill $VGPID 2>/dev/null
fi
L "DONE $(getprop ro.serialno)"

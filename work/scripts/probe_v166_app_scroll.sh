#!/system/bin/sh
# probe_v166_app_scroll.sh -- v1.66 App 侧真机验收 B：右摇杆滑动/滚动速度 + 同 tick 轴向仲裁
#  1) 竖向 1.5s：手势次数/总行程/节奏（目标：scroll_speed=4 -> 250ms/次，560px/次）
#  2) 横向 1.5s：手势次数/总行程/节奏（用户当前 hswipe_speed=3 -> 500ms/次，1152px/次）
#  3) 横/竖 1.5s 总位移比（目标 0.8~1.25）
#  4) 斜推 RX=0.40 + RY=0.73：同一时刻只允许一种触摸手势（Z xor V），无并发 SWIPE
#  5) scroll_speed=8 时竖滑节奏变化（参数真的生效）
# 用法：adb push work/scripts/probe_v166_app_scroll.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_app_scroll.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_scroll.log
HL=/data/adb/gpm/helper.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.2; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
trav(){ # $1=Z|V -> "count,total"（只统计 '^SWIPE '，排除 SWIPE_DONE/DROP/QUEUED）
  grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" '
    { if ($1==$3) kind="Z"; else kind="V"; if (kind!=want) next;
      d=(kind=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++ }
    END{ printf "%d,%d", n+0, s+0 }'; }
swipes(){ grep -a '^SWIPE ' "$HL" 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1,\2->\3,\4/' | tr '\n' ' '; }
drops(){ grep -ac 'SWIPE_DROP' "$HL" 2>/dev/null; }
done_n(){ grep -ac 'SWIPE_DONE' "$HL" 2>/dev/null; }
vcycle(){ grep -a 'vswipe' /dev/null 2>/dev/null; }
dxlog(){ logcat -d -s DexPad 2>/dev/null | grep -a 'vswipe' | sed 's/^.*DexPad *: //' | tail -6 | tr '\n' '|'; }
prefs(){ cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }
setpref(){ am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; sleep 0.5; }

wake; startp
L "=== 0. 环境 ==="
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  prefs=$(prefs)"
l3

L ""
L "=== 1. 竖向：RY=-24000 1500ms（摇杆向上=看上面的内容）==="
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 0 >/dev/null 2>&1; sleep 1.0
Z=$(trav Z); V=$(trav V)
L "  Z手势=$(echo $Z|cut -d, -f1) 总行程=$(echo $Z|cut -d, -f2)px V=$(echo $V|cut -d, -f1)"
L "  手势明细: $(swipes)"
L "  SWIPE_DONE=$(done_n) SWIPE_DROP=$(drops) | $(dxlog)"

L ""
L "=== 2. 横向：RX=+24000 1500ms ==="
: > "$HL"; logcat -c
$VG stick 3 24000 1500 0 >/dev/null 2>&1; sleep 1.0
Z=$(trav Z); V=$(trav V)
L "  V手势=$(echo $V|cut -d, -f1) 总行程=$(echo $V|cut -d, -f2)px Z=$(echo $Z|cut -d, -f1)"
L "  手势明细: $(swipes)"
L "  SWIPE_DONE=$(done_n) SWIPE_DROP=$(drops)"

L ""
L "=== 3. 横/竖 1.5s 总位移比（0.8~1.25 合格）==="
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 0 >/dev/null 2>&1; sleep 0.8
VZ=$(trav Z | cut -d, -f2)
: > "$HL"; logcat -c
$VG stick 3 24000 1500 0 >/dev/null 2>&1; sleep 0.8
VV=$(trav V | cut -d, -f2)
awk -v v="$VV" -v z="$VZ" 'BEGIN{ if(z>0) printf "  vertical=%dpx horizontal=%dpx ratio=%.3f\n", z, v, v/z; else print "  n/a" }' | tee -a "$LOG"

L ""
L "=== 4. 斜推 RX=0.40 + RY=0.73 1.5s（串扰仲裁：只允许一种手势）==="
: > "$HL"; logcat -c
$VG stick 3 24000 1500 0 >/dev/null 2>&1 &
$VG stick 4 -24000 1500 0 >/dev/null 2>&1 &
wait; sleep 1.0
Z=$(trav Z); V=$(trav V)
L "  Z=$(echo $Z|cut -d, -f1) 次/$(echo $Z|cut -d, -f2)px  V=$(echo $V|cut -d, -f1) 次/$(echo $V|cut -d, -f2)px"
L "  SWIPE_DONE=$(done_n) SWIPE_DROP=$(drops) | $(logcat -d -s DexPad 2>/dev/null | grep -a 'gesture axis arbitration' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"

L ""
L "=== 5. scroll_speed=8 时竖滑节奏（默认 4 -> 250ms/次；8 -> 120ms/次）==="
setpref --es pref scroll_speed --ei ival 8
: > "$HL"; logcat -c
$VG stick 4 -24000 1500 0 >/dev/null 2>&1; sleep 0.8
Z=$(trav Z)
L "  scroll_speed=8: Z手势=$(echo $Z|cut -d, -f1) 总行程=$(echo $Z|cut -d, -f2)px | $(dxlog)"
setpref --es pref scroll_speed --ei ival 4
L "  restored: $(prefs | grep -o 'scroll_speed[^/]*')"

L ""
L "=== 6. 并发注入检查（不应有两条 input swipe 同时在飞）==="
L "  SWIPE(开始)=$(grep -ac '^SWIPE ' "$HL") SWIPE_DONE=$(done_n) SWIPE_DROP=$(drops)"
L "DONE $(getprop ro.serialno)"

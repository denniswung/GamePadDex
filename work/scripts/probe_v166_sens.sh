#!/system/bin/sh
# probe_v166_sens.sh -- item4：灵敏度/位移/滚动次数/滑动 prep 与端到端时延 基线量化
# 用法：adb push work/scripts/probe_v166_sens.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_sens.sh"
# 只用真机真实坐标：PadProbe 的 MOUSE/hover 序列给出真实光标轨迹（不用引擎估算）
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_sens.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
# display 0 的 app 空间（overrideConfig mBounds）
gsize(){ dumpsys window displays 2>/dev/null | awk '
  /^  Display: mDisplayId=/ { id=$0; sub(/.*mDisplayId=/,"",id); sub(/[^0-9].*/,"",id) }
  id+0==0 && /overrideConfig=\{/ && match($0,/mBounds=Rect\(0, 0 - [0-9]+, [0-9]+\)/) {
    b=substr($0,RSTART,RLENGTH); gsub(/[^0-9]/," ",b); split(b,a," ");
    if (!shown) { printf "%s x %s", a[4], a[5]; shown=1 }
  }'; }
trail(){ # 真实 hover 轨迹：n / 首末点 / dt / 外推 300ms 位移
  logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ ([0-9:.]+).*MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1 \2 \3/p' | awk '
    { split($1,a,":"); t=a[1]*3600+a[2]*60+a[3]; x=$2+0; y=$3+0;
      if(n==0){fx=x;fy=y;ft=t} lx=x;ly=y;lt=t;n++ }
    END{ if(n<2){printf "no-trail(n=%d)",n} else {
      dt=(lt-ft)*1000;
      printf "n=%d from=%d,%d to=%d,%d dt=%.0fms dx=%d dy=%d px300=%.0f", n,fx,fy,lx,ly,dt,lx-fx,ly-fy,(dt>0?(lx-fx)*300/dt:0) } }'
}
ptrlog(){ logcat -d -s DexPad 2>/dev/null | grep -a 'ptr move' | tail -1 | sed 's/^.*DexPad *: //'; }
swipe_travel(){ # $1=Z|V 总行程
  grep -a '^SWIPE' /data/adb/gpm/helper.log 2>/dev/null | sed -E 's/^SWIPE [0-9]+ ([0-9]+),([0-9]+) -> ([0-9]+),([0-9]+).*/\1 \2 \3 \4/' | awk -v want="$1" '
    { if ($1==$3) kind="Z"; else kind="V"; if (kind!=want) next;
      d=(kind=="Z")?($4-$2):($3-$1); if(d<0)d=-d; s+=d; n++ }
    END{ printf "%d,%d", n+0, s+0 }'
}

wake; sleep 1; startp
L "=== 0. 屏幕（app 空间）与偏好 ==="
L "  app_size=$(gsize)"
L "  prefs=$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
L "  wm size=$(wm size | tr '\n' ' ') forced=$(settings get global display_size_forced) rot=$(settings get system user_rotation) pointer_speed=$(settings get system pointer_speed)"
L "  code_defaults: speed_phone=30 sens_x=100 sens_y=100 deadzone=160 scroll_deadzone=350 scroll_speed=4 hswipe_speed=7 wheel_speed=3 center_gain=216 idle_hide_sec=8 v_touch_scroll=true"

L ""
L "=== 1. 左摇杆定长推 300ms 的真实位移（每次先 L3 居中；满/半/1/4；各 2 次）==="
for v in -30000 -30000 -16000 -16000 -8000; do
  l3; logcat -c
  $VG stick 0 "$v" 300 0 >/dev/null 2>&1
  sleep 0.8
  L "  X=$v 300ms -> $(trail) engine:$(ptrlog)"
done
for v in -30000; do
  l3; logcat -c
  $VG stick 1 "$v" 300 0 >/dev/null 2>&1
  sleep 0.8
  L "  Y=$v 300ms (垂直) -> $(trail)"
done

L ""
L "=== 2. 右摇杆按住 1.5s：滚动次数 / 总行程 / prep ==="
: > /data/adb/gpm/helper.log; logcat -c
$VG stick 4 -24000 1500 0 >/dev/null 2>&1; sleep 1.2
L "  RY=-24000 1500ms: 注入手势=$(swipe_travel Z | cut -d, -f1) 次, 总行程=$(swipe_travel Z | cut -d, -f2) px, 单次=$(grep -a '^SWIPE' /data/adb/gpm/helper.log | head -1)"
L "  prep=[$(grep -ao 'prep=[0-9]*us' /data/adb/gpm/helper.log | sed 's/prep=//;s/us//' | tr '\n' ' ')]"
L "  DexPad vswipe=$(logcat -d -s DexPad | grep -ac 'vswipe') WHEEL=$(grep -ac '^WHEEL' /data/adb/gpm/helper.log) PadProbe_TOUCH=$(logcat -d -s PadProbe | grep -c 'TOUCH/swipe')"

: > /data/adb/gpm/helper.log; logcat -c
$VG stick 3 24000 1500 0 >/dev/null 2>&1; sleep 1.2
L "  RX=+24000 1500ms: 注入手势=$(swipe_travel V | cut -d, -f1) 次, 总行程=$(swipe_travel V | cut -d, -f2) px, prep=[$(grep -ao 'prep=[0-9]*us' /data/adb/gpm/helper.log | sed 's/prep=//;s/us//' | tr '\n' ' ')]"
L "  DexPad hswipe=$(logcat -d -s DexPad | grep -ac 'swipe vertical=false')"

L ""
L "=== 3. 滑动 prep 全量分布（6 次快速纵向）==="
: > /data/adb/gpm/helper.log
$VG chatty 304 1 10 >/dev/null 2>&1 || true
$VG stick 4 -24000 900 0 >/dev/null 2>&1; sleep 0.5
$VG stick 4 -24000 900 0 >/dev/null 2>&1; sleep 0.5
$VG stick 4 -24000 900 0 >/dev/null 2>&1; sleep 1
L "  prep=[$(grep -ao 'prep=[0-9]*us' /data/adb/gpm/helper.log | sed 's/prep=//;s/us//' | tr '\n' ' ')]"
L "  rc=0 行数=$(grep -ac 'rc=0' /data/adb/gpm/helper.log)"

L ""
L "=== 4. 引擎节拍与链路延迟 ==="
L "  $(logcat -d -s DexPad | grep -aE 'hb ready|lat n=' | tail -3 | tr '\n' '|')"

L ""
L "DONE $(getprop ro.serialno)"

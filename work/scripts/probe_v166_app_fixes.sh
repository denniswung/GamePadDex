#!/system/bin/sh
# probe_v166_app_fixes.sh -- v1.66 App 侧真机验收 A：
#   1) L3 闭环居中（连续 5 次 + 空闲隐藏后 + d-pad 导航后，阈值 |err|<=80px，目标实际 <=8px）
#   2) 左摇杆 dpi/曲线：满推 300ms 位移（目标 0.9~1.2 屏宽）、半推、0.24 推、边缘减速
#   3) 光标四方向可达真实边缘（含 d-pad 后 / 空闲隐藏后），估算 vs 真实
# 用法：adb push work/scripts/probe_v166_app_fixes.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_app_fixes.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_fixes.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.2; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.2; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.2; }
click(){ $VG key 304 60 0 >/dev/null 2>&1; sleep 0.5; }
stick(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.35; }
stickq(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.15; }
hat(){ $VG hat 0 1 "$1" >/dev/null 2>&1; sleep 0.4; }
gsize(){ dumpsys window displays 2>/dev/null | sed -n 's/.*cur=\([0-9]*\)x\([0-9]*\).*/\1 \2/p' | head -1; }
cxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
trail(){ logcat -d -s PadProbe 2>/dev/null | sed -n -E 's/^[0-9-]+ ([0-9:.]+).*MOUSE\/hover x=([0-9]+) y=([0-9]+).*/\1 \2 \3/p' | awk '
    { split($1,a,":"); t=a[1]*3600+a[2]*60+a[3]; x=$2+0; y=$3+0;
      if(n==0){fx=x;fy=y;ft=t} lx=x;ly=y;lt=t;n++ }
    END{ if(n<2){printf "no-trail(n=%d)",n} else {
      dt=(lt-ft)*1000;
      printf "n=%d from=%d,%d to=%d,%d dt=%.0fms dx=%d dy=%d", n,fx,fy,lx,ly,dt,lx-fx,ly-fy } }'; }
est(){ logcat -d -s DexPad 2>/dev/null | grep -a 'ptr move' | tail -1 | sed 's/^.*DexPad *: //'; }
say(){ logcat -d -s DexPad 2>/dev/null | grep -aE 'CENTER_OK|CENTER_NOCURSOR|moveGain|L3 probe|L3 correction|L3 center begin|L3 clears|ptr synced|edge slow|at screen edge|perf tick' | tail -"${1:-14}" | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
sane(){ # 确认 padtest 在前台且点击能被记录
  cmd statusbar collapse >/dev/null 2>&1; sleep 0.4
  logcat -c; stick 0 -30000 250; click
  A=$(cxy); F=$(dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*padtest')
  if [ -z "$A" ] || [ "$F" -lt 1 ]; then
    L "  [sane] no click / not focused (focus=$F) -> restart padtest"
    startp; logcat -c; stick 0 -30000 250; click; A=$(cxy)
    F=$(dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*padtest')
  fi
  L "  [sane] click=$A padtest_focused=$F shade=$(dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*NotificationShade')"
}

wake; pin; startp
GS=$(gsize); GW=$(echo "$GS" | awk '{print $1}'); GH=$(echo "$GS" | awk '{print $3}')
[ -z "$GW" ] && GW=2560
[ -z "$GH" ] && GH=1600
L "=== 0. 环境 ==="
L "  app_size=${GW}x${GH} rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  apk_sha=$(sha256sum $(pm path $PKG | sed 's/package://') | cut -d' ' -f1)"
L "  helper_sha=$(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
L "  prefs=$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
L "  helper=$(md5sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)"
sane
l3; click   # 第一次 L3：让引擎日志里出现几何与 gain

L ""
L "=== 1. L3 连续 5 次（T1..T5）==="
for i in 1 2 3 4 5; do
  case $i in
    2) stick 0 -30000 400 ;;
    3) stick 1 30000 400; stick 0 30000 400 ;;
    4) L "  [T4 置空闲 9s，等 idle_hide]"; sleep 9 ;;
    5) L "  [T5 先 d-pad 导航]"; hat 200; hat 200 ;;
  esac
  logcat -c; l3; click
  A=$(cxy); AX=${A% *}; AY=${A#* }
  CH=$(say 6)
  E=$(awk -v ax="$AX" -v ay="$AY" -v w="$GW" -v h="$GH" 'BEGIN{ if(ax=="") print "n/a"; else printf "err=%d,%d", ax-w/2, ay-h/2 }')
  L "  T$i actual=[$A] $E | $CH"
done

L ""
L "=== 2. 左摇杆 300ms 位移（L3 后先推到左边缘，避免右边缘夹取）==="
for v in 30000 30000 16000 8000 6000; do
  l3; stick 0 -30000 450; sleep 0.3
  logcat -c
  $VG stick 0 "$v" 300 0 >/dev/null 2>&1
  sleep 0.7
  L "  X=$v 300ms -> $(trail) | est:$(est)"
done
L "  (屏宽 $GW；目标满推 0.9~1.2 屏宽 = $((GW*9/10))~$((GW*12/10)) px)"

L ""
L "=== 3. 边缘减速（同一个 0.49 推 300ms：屏幕中心 vs 左边缘）==="
l3; logcat -c; stick 0 16000 300
L "  center: $(trail) | $(say 3)"
l3; stick 0 -30000 450; sleep 0.3; logcat -c; stick 0 16000 300
L "  edge  : $(trail) | $(say 3)"

L ""
L "=== 4. 四方向可达真实边缘 + 贴边后 5x200ms 零位移 + 反向一步 ==="
for d in "left:0:-30000:right:30000" "right:0:30000:left:-30000" "up:1:-30000:down:30000" "down:1:30000:up:-30000"; do
  NAME=${d%%:*}; R=${d#*:}; AXIS=${R%%:*}; R2=${R#*:}; VAL=${R2%%:*}; R3=${R2#*:}; RNAME=${R3%%:*}; RVAL=${R3#*:}
  l3
  logcat -c
  stick "$AXIS" "$VAL" 1400
  click
  A1=$(cxy)
  for k in 1 2 3 4 5; do stickq "$AXIS" "$VAL" 200; done
  click
  A2=$(cxy)
  logcat -c
  stick "$AXIS" "$RVAL" 250
  sleep 0.3
  click
  A3=$(cxy)
  L "  $NAME: edge1=[$A1] after5x200=[$A2] reverse250=[$A3] | est:$(est) | $(say 5)"
done

L ""
L "=== 5. d-pad 导航后 / 空闲隐藏后 仍可推杆到边缘 ==="
hat 200; hat 200
logcat -c
stick 0 -30000 1400
click
L "  after-dpad push-left:  actual=[$(cxy)] | $(say 6)"
sleep 9
logcat -c
stick 0 30000 1400
click
L "  after-idle-hide push-right: actual=[$(cxy)] | $(say 6)"

L ""
L "=== 6. 引擎自报性能 / 增益 ==="
L "  perf: $(logcat -d -s DexPad 2>/dev/null | grep -a 'perf tick' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  gain: $(logcat -d -s DexPad 2>/dev/null | grep -a 'moveGain calibrated' | tail -4 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  prefs_after_gain=$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | grep -o 'move_gain[^/]*')"
L "DONE $(getprop ro.serialno) size=${GW}x${GH}"

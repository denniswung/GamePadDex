#!/system/bin/sh
# probe_v166_boundary.sh -- item3：光标在某些区域被夹住（方向 / 估算 vs 真实落点 / 隐藏重建 / d-pad 粘性导航）
# 用法：adb push work/scripts/probe_v166_boundary.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_boundary.sh"
# 记录：每次推杆后 真实落点(PadProbe click-down) + 引擎估算(DexPad ptr move ... at X,Y)
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_boundary.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
click(){ $VG key 304 80 0 >/dev/null 2>&1; sleep 0.45; }
push(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.35; }
clickxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
est(){ logcat -d -s DexPad 2>/dev/null | grep -a 'ptr move' | tail -1 | sed -n 's/.*at \([0-9-]*\),\([0-9-]*\).*/\1,\2/p'; }
step(){ # $1=label $2=axis $3=value $4=ms
  logcat -c; push "$2" "$3" "$4"; click
  A=$(clickxy); AX=${A% *}; AY=${A#* }
  L "  $1 -> actual=$AX,$AY engine_est=$(est) delta_to_edge: x=$((W - AX)) y=$((H - AY))"
}

wake; sleep 1; startp
S=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p')
W=${S% *}; H=${S#* }; [ -z "$W" ] && W=2560; [ -z "$H" ] && H=1600
L "=== 0. 几何 ==="
L "  app_size=${W}x${H} forced=$(settings get global display_size_forced) rot=$(settings get system user_rotation) pointer_speed=$(settings get system pointer_speed)"

L ""
L "=== T1. L3 基线（真实落点 vs 估算）==="
logcat -c; l3; click
A=$(clickxy); AX=${A% *}; AY=${A#* }
L "  after L3: actual=$AX,$AY err=$((AX - W/2)),$((AY - H/2)) engine_est=$(est) | $(logcat -d -s DexPad | grep -a 'cursor centered' | tail -1 | sed 's/^.*DexPad *: //')"

L ""
L "=== T2. 向右推 4x300ms：看真实 x 何时停止、估算是否还在涨（夹住带）==="
step "R1" 0 30000 300
step "R2" 0 30000 300
step "R3" 0 30000 300
step "R4" 0 30000 300

L ""
L "=== T3. 到右边界后继续向右 2 次（应完全不动）==="
logcat -c; push 0 30000 400; click
A=$(clickxy); L "  R5 -> actual=$A engine_est=$(est)"
logcat -c; push 0 30000 400; click
A=$(clickxy); L "  R6 -> actual=$A engine_est=$(est)"

L ""
L "=== T4. 从右边界向左 2x300ms（应立刻回退）==="
step "L1" 0 -30000 300
step "L2" 0 -30000 300

L ""
L "=== T5. 向下推 4x300ms（下边界）==="
step "D1" 1 30000 300
step "D2" 1 30000 300
step "D3" 1 30000 300
step "D4" 1 30000 300

L ""
L "=== T6. 下边界后向上 2x300ms ==="
step "U1" 1 -30000 300
step "U2" 1 -30000 300

L ""
L "=== T7. 空闲隐藏（10s）后小幅移动再点击：位置是否原地 ==="
logcat -c; l3; click
A=$(clickxy); L "  before-idle: actual=$A"
sleep 10
L "  hidden=$(logcat -d -s DexPad | grep -ac 'pointer hidden') shown=$(logcat -d -s DexPad | grep -ac 'pointer shown')"
logcat -c; push 0 6000 200; click
A=$(clickxy); L "  after-idle-move: actual=$A (期望与 before-idle 同位置 + 小位移)  shown_log=$(logcat -d -s DexPad | grep -a 'pointer shown' | tail -1 | sed 's/^.*DexPad *: //')"

L ""
L "=== T8. d-pad 粘性导航后推杆/点击 ==="
$VG hat 0 1 200 >/dev/null 2>&1; sleep 0.3
$VG hat 0 1 200 >/dev/null 2>&1; sleep 0.5
logcat -c; push 0 -30000 300; click
A=$(clickxy); L "  after-dpad: actual=$A nav_log=$(logcat -d -s DexPad | grep -a 'navigation' | tail -2 | tr '\n' '|')"

L ""
L "=== T9. 竖屏几何（user_rotation=0 -> 1600x2560）下的 L3 与推杆 ==="
settings put system user_rotation 0 >/dev/null 2>&1; sleep 2.5
S2=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p')
logcat -c; l3; click
A=$(clickxy); L "  portrait center_log=$(logcat -d -s DexPad | grep -a 'cursor centered' | tail -1 | sed 's/^.*DexPad *: //') actual=$A  (W,H 见日志)"
logcat -c; push 0 30000 400; click
A=$(clickxy); L "  portrait push-right actual=$A engine_est=$(est)"
settings put system user_rotation 1 >/dev/null 2>&1; sleep 2.5
L "  restored rotation=$(settings get system user_rotation)"

L ""
L "=== T10. 引擎 tick 与估算日志 ==="
L "  $(logcat -d -s DexPad | grep -aE 'ptr move|hb ready' | tail -4 | tr '\n' '|')"
L "DONE $(getprop ro.serialno)"

#!/system/bin/sh
# v1.49 全按键测试：目标 App = 手柄测试页（GpTest）
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
PRE=2500
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
dlog() { logcat -d -s DexPad 2>/dev/null; }
glog() { logcat -d -s GpTest 2>/dev/null; }
hl()   { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
dbg() { am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
setb() { dbg --es pref "$1" --ez bval "$2"; }
sets() { dbg --es pref "$1" --es sval "$2"; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
vp()   { am start -n $PKG/.GamepadTestActivity >/dev/null 2>&1; sleep 1.4; }
# d9 <desc> <regex>  -> 引擎日志
d9() { if dlog | grep -qE "$2"; then ok "$1"; else bad "$1 [$(dlog | grep DexPad | tail -1)]"; fi; }
# g9 <desc> <regex>  -> 测试页
g9() { if glog | grep -qE "$2"; then ok "$1"; else bad "$1 [no GpTest match]"; fi; }
# h9 <since> <desc> <regex> -> 助手
h9() { if hl "$1" | grep -qE "$3"; then ok "$2"; else bad "$2 [$(hl "$1" | tail -1)]"; fi; }

wake
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 5
vp

# ---------------- L ----------------
dlog | grep -q 'engine started' && ok "L-01 引擎启动" || bad "L-01 engine"
N=0
while [ $N -lt 4 ]; do dlog | grep -q 'hb ready=true' && break; sleep 1.5; N=$((N+1)); done
dlog | grep -q 'hb ready=true' && ok "L-02 助手链路" || bad "L-02 link"
[ "$N" -lt 4 ] && ok "L-03 鼠标模式 on" || bad "L-03 mode"
LAST=$(hl 0 | grep -n 'SELFTEST begin' | tail -1 | cut -d: -f1)
CAPS=$(hl 0 | tail -n +${LAST:-1} | grep -c 'CAP ')
MISS=$(hl 0 | tail -n +${LAST:-1} | grep 'CAP ' | grep ' 0$' | grep -v devices | wc -l)
[ "$CAPS" -ge 9 ] && [ "$MISS" -eq 0 ] && ok "L-04 自检 $CAPS 项" || bad "L-04 自检 caps=$CAPS miss=$MISS"

# ---------------- S 单击 ----------------
logcat -c; $VG key 304 120 $PRE >/dev/null 2>&1; sleep 0.8
g9 "S-01 A -> 左键" 'click down'

logcat -c; L=$(hcount); $VG key 305 120 $PRE >/dev/null 2>&1; sleep 0.8
h9 "$L" "S-02 B -> 返回" 'KEYON 0 4'
vp

logcat -c; L=$(hcount); $VG key 307 120 $PRE >/dev/null 2>&1; sleep 0.8
if ! glog | grep -q 'click down' && ! hl "$L" | grep -q 'KEYON'; then ok "S-03 X -> 无动作"; else bad "S-03 X"; fi

logcat -c; L=$(hcount); $VG key 308 120 $PRE >/dev/null 2>&1; sleep 0.8
h9 "$L" "S-04 Y -> Home" 'KEYON 0 3'
vp

logcat -c; $VG key 310 500 $PRE >/dev/null 2>&1; sleep 0.8
if glog | grep -qE 'scroll v=|wheel' ; then ok "S-05 LB -> 内容上滚"; else d9 "S-05 LB -> 手指出下滑（内容上滚）" 'scroll_swipe_down started by lb'; fi

logcat -c; $VG key 311 500 $PRE >/dev/null 2>&1; sleep 0.8
if glog | grep -qE 'scroll v=|wheel' ; then ok "S-06 RB -> 内容下滑"; else d9 "S-06 RB -> 手指上滑（内容下滑）" 'scroll_swipe_up started by rb'; fi

logcat -c; $VG key 312 120 $PRE >/dev/null 2>&1; sleep 0.8
d9 "S-07 LT -> 缩小" 'zoom out -> \[113, 69\]'

logcat -c; $VG key 313 120 $PRE >/dev/null 2>&1; sleep 0.8
d9 "S-08 RT -> 放大" 'zoom in -> \[113, 81\]'

logcat -c; L=$(hcount); $VG key 317 120 $PRE >/dev/null 2>&1; sleep 0.8
h9 "$L" "S-09 L3 -> 居中" 'CENTER'

logcat -c; L=$(hcount); $VG key 318 120 $PRE >/dev/null 2>&1; sleep 0.8
h9 "$L" "S-10 R3 -> 静音" 'KEYON 0 164'

logcat -c; $VG key 315 120 $PRE >/dev/null 2>&1; sleep 1.2
d9 "S-11 START -> 切换 App" 'switch app on display'
vp

logcat -c; L=$(hcount); $VG key 314 120 $PRE >/dev/null 2>&1; sleep 1.0
h9 "$L" "S-12 SELECT -> 通知栏" 'NOTIF'
input keyevent KEYCODE_BACK >/dev/null 2>&1; sleep 0.5
vp

logcat -c; L=$(hcount); $VG key 316 150 $PRE >/dev/null 2>&1; sleep 0.8
if ! glog | grep -q 'click down' && ! hl "$L" | grep -qE 'KEYON|NOTIF|POWER|SWIPE'; then ok "S-13 GUIDE 短按 -> 无动作"; else bad "S-13 GUIDE"; fi

logcat -c; $VG hold 316 900 $PRE >/dev/null 2>&1; sleep 0.8
d9 "S-13b GUIDE 长按 -> 帮助" 'guide help'
input keyevent KEYCODE_BACK >/dev/null 2>&1; sleep 0.4
vp

logcat -c; $VG key 130 120 $PRE >/dev/null 2>&1; sleep 0.8
d9 "S-14 SHARE -> 关鼠标模式" 'toggle -> mouse mode false'
logcat -c; $VG key 130 120 $PRE >/dev/null 2>&1; sleep 0.8
d9 "S-15 SHARE -> 开鼠标模式" 'toggle -> mouse mode true'

logcat -c; $VG hat 0 1 150 $PRE >/dev/null 2>&1; sleep 0.8
g9 "S-16 D-pad ↑" 'key down code=19'
logcat -c; $VG hat 0 -1 150 0 >/dev/null 2>&1; sleep 0.8
g9 "S-16b D-pad ↓" 'key down code=20'
logcat -c; $VG hat -1 0 150 0 >/dev/null 2>&1; sleep 0.8
g9 "S-16c D-pad ←" 'key down code=21'
logcat -c; $VG hat 1 0 150 0 >/dev/null 2>&1; sleep 0.8
g9 "S-16d D-pad →" 'key down code=22'

# ---------------- D 双击 ----------------
logcat -c; $VG double 307 60 110 $PRE >/dev/null 2>&1; sleep 1.0
d9 "D-01 X 双击 -> 多任务" 'double x -> recents'
vp
logcat -c; L=$(hcount); $VG double 318 60 110 $PRE >/dev/null 2>&1; sleep 1.0
d9 "D-02 R3 双击 -> 播放/暂停" 'double r3 -> play_pause'
h9 "$L" "D-02b R3 双击注入 play/pause" 'KEYON 0 85|KCOMBO.*85'
logcat -c; $VG dblstick 318 4 20000 $PRE >/dev/null 2>&1; sleep 1.0
d9 "D-03 R3 双击 + 右摇杆 -> 取消" 'double r3 cancelled'

# ---------------- G 长按 ----------------
logcat -c; $VG hold 307 900 $PRE >/dev/null 2>&1; sleep 0.8
if ! dlog | grep -q 'long x ->'; then ok "G-01 默认长按 -> 无动作"; else bad "G-01 default long"; fi
sets lng_x recents; sleep 0.8
logcat -c; L=$(hcount); $VG hold 307 900 $PRE >/dev/null 2>&1; sleep 0.8
d9 "G-02 长按 X -> 多任务" 'long x -> recents'
h9 "$L" "G-02b 长按注入多任务" 'KEYON 0 187'
if ! glog | grep -q 'click down'; then ok "G-03 长按抑制单击"; else bad "G-03 long suppresses click"; fi
sets lng_x none; sleep 0.6

# ---------------- C 组合 ----------------
logcat -c; L=$(hcount); $VG combo 307 103 1200 $PRE >/dev/null 2>&1; sleep 1.2
N=$(hl "$L" | grep -c 'KEYON 0 24')
d9 "C-01 X+↑ 音量+" 'mix 0 x\+up -> volume_up'
[ "$N" -ge 2 ] && ok "C-01b 音量连续 ($N 次)" || bad "C-01b repeat n=$N"

logcat -c; L=$(hcount); $VG combo 307 108 500 $PRE >/dev/null 2>&1; sleep 0.9
d9 "C-02 X+↓ 音量-" 'mix 1 x\+down -> volume_down'
h9 "$L" "C-02b 注入音量-" 'KEYON 0 25'

logcat -c; L=$(hcount); $VG combo 307 105 400 $PRE >/dev/null 2>&1; sleep 0.9
d9 "C-03 X+← 上一首" 'mix 2 x\+left -> prev_track'
h9 "$L" "C-03b 注入上一首" 'KEYON 0 88'

logcat -c; L=$(hcount); $VG combo 307 106 400 $PRE >/dev/null 2>&1; sleep 0.9
d9 "C-04 X+→ 下一首" 'mix 3 x\+right -> next_track'
h9 "$L" "C-04b 注入下一首" 'KEYON 0 87'

logcat -c; L=$(hcount); $VG combo 307 310 500 $PRE >/dev/null 2>&1; sleep 1.0
SW=$(hl "$L" | grep -m1 'SWIPE')
d9 "C-05 X+LB 左滑" 'mix 4 x\+lb -> wheel_left'
DX=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),[0-9]* -> \([0-9]*\),.*/\1 \2/p' | awk '{d=$2-$1; if(d<0)d=-d; print d}')
[ -n "$DX" ] && [ "$DX" -ge 1200 ] && ok "C-05b 左滑宽度 ${DX}px" || bad "C-05b width=$DX [$SW]"

logcat -c; L=$(hcount); $VG combo 307 311 500 $PRE >/dev/null 2>&1; sleep 1.0
d9 "C-06 X+RB 右滑" 'mix 5 x\+rb -> wheel_right'
hl "$L" | grep -q 'SWIPE' && ok "C-06b 右滑注入" || bad "C-06b no swipe"

logcat -c; L=$(hcount); $VG combo 308 317 500 $PRE >/dev/null 2>&1; sleep 1.2
d9 "C-07 Y+L3 电源" 'mix 9 y\+l3 -> power'
h9 "$L" "C-07b 电源注入" 'POWER'
wake; vp

logcat -c; L=$(hcount); $VG combo 314 315 1300 $PRE >/dev/null 2>&1; sleep 1.3
d9 "C-08 SELECT+START 开关屏" 'select\+start -> screen toggle'
h9 "$L" "C-08b 开关屏注入" 'POWER'
wake; vp

logcat -c; $VG combo 307 316 2000 $PRE >/dev/null 2>&1; sleep 1.5
d9 "C-09 X+GUIDE 强停" 'force stop by X\+GUIDE'
am force-stop $PKG >/dev/null 2>&1; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4; vp

logcat -c; $VG holdstick 307 0 20000 800 $PRE >/dev/null 2>&1; sleep 0.8
SLOW=$(dlog | grep 'ptr move' | sed -n 's/.*dx=\([0-9-]*\) dy=\([0-9-]*\).*/\1 \2/p' | awk '{s+=($1<0?-$1:$1)+($2<0?-$2:$2)} END{printf "%.0f", s+0}')
logcat -c; $VG stick 0 20000 800 $PRE >/dev/null 2>&1; sleep 0.8
FAST=$(dlog | grep 'ptr move' | sed -n 's/.*dx=\([0-9-]*\) dy=\([0-9-]*\).*/\1 \2/p' | awk '{s+=($1<0?-$1:$1)+($2<0?-$2:$2)} END{printf "%.0f", s+0}')
[ -n "$SLOW" ] && [ -n "$FAST" ] && [ "$SLOW" -lt "$FAST" ] && ok "C-10 X+左摇杆 慢速 ($SLOW < $FAST)" || bad "C-10 slow ($SLOW vs $FAST)"

# ---------------- F 焦点窗口 ----------------
logcat -c; $VG hatkey 1 304 $PRE >/dev/null 2>&1; sleep 1.0
d9 "F-01 D-pad + A -> 激活焦点" 'A -> DPAD_CENTER'

logcat -c; sleep 2.2; $VG key 304 120 0 >/dev/null 2>&1; sleep 0.8
if glog | grep -q 'click down' && ! dlog | grep -q 'A -> DPAD_CENTER'; then ok "F-02 窗口后 A -> 左键"; else bad "F-02 A after window"; fi

logcat -c; $VG hatkey 1 304 $PRE >/dev/null 2>&1; sleep 0.9
logcat -c; $VG stick 0 20000 400 0 >/dev/null 2>&1; sleep 0.5
$VG key 304 120 0 >/dev/null 2>&1; sleep 0.8
if dlog | grep -q 'native navigation OFF (stick moved)' && glog | grep -q 'click down'; then ok "F-03 摇杆一动恢复左键"; else bad "F-03 stick restores"; fi

# ---------------- R 摇杆 ----------------
logcat -c; $VG stick 0 20000 700 $PRE >/dev/null 2>&1; sleep 0.9
g9 "R-01 左摇杆 -> 指针" 'hover|GpTest.*move'

logcat -c; L=$(hcount); $VG stick 4 20000 900 $PRE >/dev/null 2>&1; sleep 1.0
hl "$L" | grep -qE 'SWIPE|WHEEL' && ok "R-02 右摇杆上下 -> 滚动" || bad "R-02 roll [$(hl "$L" | tail -1)]"

logcat -c; L=$(hcount); $VG stick 3 20000 900 $PRE >/dev/null 2>&1; sleep 1.0
hl "$L" | grep -q 'SWIPE' && ok "R-03 右摇杆左右 -> 横滑" || bad "R-03 hswipe [$(hl "$L" | tail -1)]"

logcat -c; L=$(hcount); ( $VG key 311 1200 $PRE >/dev/null 2>&1 & ); sleep 0.6
$VG stick 4 20000 400 0 >/dev/null 2>&1; sleep 1.6
hl "$L" | grep -q 'wheel stopped by rb' && ok "R-04 摇杆抢占按键滚动" || bad "R-04 preempt [$(hl "$L" | grep -c 'wheel stopped')]"

logcat -c; $VG holdstick 317 0 20000 300 $PRE >/dev/null 2>&1; sleep 0.6
N=$(dlog | grep -c 'ptr move')
[ "$N" -eq 0 ] && ok "R-05 L3 居中锁杆 250ms" || bad "R-05 center lock ($N)"

logcat -c; setb role_swap true; sleep 1.0
$VG stick 0 20000 600 0 >/dev/null 2>&1; sleep 0.8
LEFT=$(dlog | grep -c 'ptr move')
logcat -c; $VG stick 3 20000 600 0 >/dev/null 2>&1; sleep 0.8
RIGHT=$(dlog | grep -c 'ptr move')
[ "$LEFT" -eq 0 ] && [ "$RIGHT" -gt 0 ] && ok "R-06 角色互换（右杆=指针）" || bad "R-06 role swap (L=$LEFT R=$RIGHT)"
setb role_swap false; sleep 0.8

# ---------------- X 不该发生 ----------------
logcat -c; $VG combo 307 316 700 $PRE >/dev/null 2>&1; sleep 1.2
if ! dlog | grep -q 'double x ->'; then ok "X-01 X+GUIDE 不触发双击"; else bad "X-01"; fi
am force-stop $PKG >/dev/null 2>&1; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4; vp

logcat -c; $VG combo 307 103 400 $PRE >/dev/null 2>&1; sleep 1.0
if ! dlog | grep -q 'double x ->'; then ok "X-02 X+方向键 不触发双击"; else bad "X-02"; fi

logcat -c; $VG combo 307 108 300 $PRE >/dev/null 2>&1; sleep 0.9
if ! glog | grep -q 'click down'; then ok "X-03 组合抑制 X 单键"; else bad "X-03"; fi

CR=$(logcat -d 2>/dev/null | grep -cE 'FATAL EXCEPTION')
[ "$CR" -eq 0 ] && ok "X-04 全程无 FATAL" || bad "X-04 FATAL=$CR"

wake
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

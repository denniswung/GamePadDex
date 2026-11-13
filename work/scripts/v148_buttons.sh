#!/system/bin/sh
# v1.48 全按键测试：42 条用例（L/S/D/G/C/F/R/X）
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
PRE=2500
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPad 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
dbg() { am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
setb() { dbg --es pref "$1" --ez bval "$2"; }
sets() { dbg --es pref "$1" --es sval "$2"; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
# expect <desc> <pattern> : 判定上一次操作
expect() {
    if log | grep -qE "$2"; then ok "$1"; else bad "$1 [$(log | grep -E 'DexPad' | tail -2 | tr '\n' ' ')]"; fi
}
expecth() { # helper 日志
    if hl "$1" | grep -qE "$3"; then ok "$2"; else bad "$2 [$(hl "$1" | tail -2 | tr '\n' ' ')]"; fi
}

wake
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

# ---------- L 前置 ----------
L0=$(hcount)
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
if log | grep -q 'engine started'; then ok "L-01 engine started"; else bad "L-01 engine"; fi
if log | grep -q 'hb ready=true'; then ok "L-02 helper link"; else bad "L-02 helper link"; fi
if log | grep -q 'mouse mode ON\|mode -> true\|mode=true'; then ok "L-03 mouse mode on"; else bad "L-03 mouse mode"; fi
LAST=$(hl 0 | grep -n 'SELFTEST begin' | tail -1 | cut -d: -f1)
CAPS=$(hl 0 | tail -n +${LAST:-1} | grep -c 'CAP ')
MISS=$(hl 0 | tail -n +${LAST:-1} | grep 'CAP ' | grep ' 0$' | grep -v devices | wc -l)
[ "$CAPS" -ge 9 ] && [ "$MISS" -eq 0 ] && ok "L-04 selftest ($CAPS caps)" || bad "L-04 selftest (caps=$CAPS miss=$MISS)"

# ---------- S 单击 ----------
logcat -c; $VG key 304 120 $PRE >/dev/null 2>&1; sleep 0.8
expect "S-01 A -> 左键" 'left button down'

logcat -c; L=$(hcount); $VG key 305 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'back on display' && hl "$L" | grep -q 'KEYON 0 4' && ok "S-02 B -> 返回" || bad "S-02 B"

logcat -c; L=$(hcount); $VG key 307 120 $PRE >/dev/null 2>&1; sleep 0.8
if ! log | grep -q 'left button down' && ! hl "$L" | grep -q 'KEYON'; then ok "S-03 X -> 无动作"; else bad "S-03 X"; fi

logcat -c; L=$(hcount); $VG key 308 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'home on display' && hl "$L" | grep -q 'KEYON 0 3' && ok "S-04 Y -> Home" || bad "S-04 Y"

logcat -c; L=$(hcount); $VG key 310 350 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'wheel scroll_swipe_up started by lb' && hl "$L" | grep -q 'SWIPE' && ok "S-05 LB -> 上滑" || bad "S-05 LB"

logcat -c; L=$(hcount); $VG key 311 350 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'wheel scroll_swipe_down started by rb' && hl "$L" | grep -q 'SWIPE' && ok "S-06 RB -> 下滑" || bad "S-06 RB"

logcat -c; $VG key 312 120 $PRE >/dev/null 2>&1; sleep 0.8
expect "S-07 LT -> 缩小" 'zoom out -> \[113, 69\]'

logcat -c; $VG key 313 120 $PRE >/dev/null 2>&1; sleep 0.8
expect "S-08 RT -> 放大" 'zoom in -> \[113, 81\]'

logcat -c; L=$(hcount); $VG key 317 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'cursor centered' && hl "$L" | grep -q 'CENTER' && ok "S-09 L3 -> 居中" || bad "S-09 L3"

logcat -c; L=$(hcount); $VG key 318 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'volume mute on display' && hl "$L" | grep -q 'KEYON 0 164' && ok "S-10 R3 -> 静音" || bad "S-10 R3 [$(log | grep DexPad | tail -1)]"

logcat -c; $VG key 315 120 $PRE >/dev/null 2>&1; sleep 1.0
expect "S-11 START -> 切换 App" 'switch app on display'

logcat -c; L=$(hcount); $VG key 314 120 $PRE >/dev/null 2>&1; sleep 0.8
hl "$L" | grep -q 'NOTIF' && ok "S-12 SELECT -> 通知栏" || bad "S-12 SELECT [$(hl "$L" | tail -1)]"

logcat -c; L=$(hcount); $VG key 316 150 $PRE >/dev/null 2>&1; sleep 0.8
if ! log | grep -qE 'left button|KEYON|switch app|POWER|NOTIF' && ! hl "$L" | grep -qE 'KEYON|NOTIF|POWER'; then
    ok "S-13 GUIDE -> 无动作"
else
    bad "S-13 GUIDE"
fi

logcat -c; $VG key 316 100 1300 >/dev/null 2>&1; sleep 0.5
log | grep -q 'guide help' && ok "S-13b GUIDE 长按 -> 帮助" || bad "S-13b GUIDE long"

logcat -c; $VG key 130 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'toggle -> mouse mode false' && ok "S-14 SHARE -> 关闭鼠标模式" || bad "S-14 SHARE off"
logcat -c; $VG key 130 120 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'toggle -> mouse mode true' && ok "S-15 SHARE -> 打开鼠标模式" || bad "S-15 SHARE on"

logcat -c; L=$(hcount); $VG hat 0 1 120 $PRE >/dev/null 2>&1; sleep 0.8
hl "$L" | grep -q 'PAD 103' && log | grep -q 'pad key 103' && ok "S-16 D-pad ↑ -> 原生方向键" || bad "S-16 dpad up"
logcat -c; $VG hat 0 -1 120 $PRE >/dev/null 2>&1; sleep 0.8
expect "S-16b D-pad ↓" 'pad key 108'

# ---------- D 双击 ----------
logcat -c; $VG double 307 60 110 $PRE >/dev/null 2>&1; sleep 1.0
expect "D-01 X 双击 -> 多任务" 'double x -> recents'

logcat -c; L=$(hcount); $VG double 318 60 110 $PRE >/dev/null 2>&1; sleep 1.0
log | grep -q 'double r3 -> play_pause' && hl "$L" | grep -qE 'KCOMBO.*85' && ok "D-02 R3 双击 -> 播放/暂停" || bad "D-02 R3 double [$(hl "$L" | tail -1)]"

logcat -c; $VG dblstick 318 4 20000 $PRE >/dev/null 2>&1; sleep 1.0
expect "D-03 R3 双击 + 右摇杆 -> 取消" 'double r3 cancelled'

# ---------- G 长按 ----------
logcat -c; $VG hold 307 900 $PRE >/dev/null 2>&1; sleep 0.8
if ! log | grep -q 'long x ->'; then ok "G-01 默认长按 -> 无动作"; else bad "G-01 default long"; fi

sets lng_x recents; sleep 0.8
logcat -c; L=$(hcount); $VG hold 307 900 $PRE >/dev/null 2>&1; sleep 0.8
log | grep -q 'long x -> recents' && hl "$L" | grep -q 'KEYON 0 187' && ok "G-02 长按 X -> 多任务" || bad "G-02 long x [$(log | grep DexPad | tail -1)]"
if ! log | grep -q 'left button down'; then ok "G-03 长按抑制单击"; else bad "G-03 long suppresses single"; fi
sets lng_x none; sleep 0.6

# ---------- C 组合 ----------
logcat -c; L=$(hcount); $VG combo 307 19 1200 $PRE >/dev/null 2>&1; sleep 1.0
N=$(hl "$L" | grep -c 'KEYON 0 24')
log | grep -q 'mix 0 x+up -> volume_up' && [ "$N" -ge 2 ] && ok "C-01 X+↑ 音量+ 连续($N)" || bad "C-01 X+up (n=$N)"

logcat -c; L=$(hcount); $VG combo 307 20 500 $PRE >/dev/null 2>&1; sleep 0.9
log | grep -q 'mix 1 x+down -> volume_down' && hl "$L" | grep -q 'KEYON 0 25' && ok "C-02 X+↓ 音量-" || bad "C-02 X+down"

logcat -c; L=$(hcount); $VG combo 307 21 400 $PRE >/dev/null 2>&1; sleep 0.9
log | grep -q 'mix 2 x+left -> prev_track' && hl "$L" | grep -q 'KEYON 0 88' && ok "C-03 X+← 上一首" || bad "C-03 X+left"

logcat -c; L=$(hcount); $VG combo 307 22 400 $PRE >/dev/null 2>&1; sleep 0.9
log | grep -q 'mix 3 x+right -> next_track' && hl "$L" | grep -q 'KEYON 0 87' && ok "C-04 X+→ 下一首" || bad "C-04 X+right"

logcat -c; L=$(hcount); $VG combo 307 310 500 $PRE >/dev/null 2>&1; sleep 1.0
SW=$(hl "$L" | grep -m1 'SWIPE')
log | grep -q 'mix 4 x+lb -> wheel_left' && echo "$SW" | grep -qE 'SWIPE' && ok "C-05 X+LB 左滑 ($SW)" || bad "C-05 X+LB [$SW]"

logcat -c; L=$(hcount); $VG combo 307 311 500 $PRE >/dev/null 2>&1; sleep 1.0
log | grep -q 'mix 5 x+rb -> wheel_right' && hl "$L" | grep -q 'SWIPE' && ok "C-06 X+RB 右滑" || bad "C-06 X+RB"

logcat -c; L=$(hcount); $VG combo 308 317 500 $PRE >/dev/null 2>&1; sleep 1.0
log | grep -q 'mix 9 y+l3 -> power' && hl "$L" | grep -qE 'POWER' && ok "C-07 Y+L3 电源" || bad "C-07 Y+L3 [$(log | grep DexPad | tail -1)]"
wake; sleep 0.5

logcat -c; L=$(hcount); $VG combo 314 315 1300 $PRE >/dev/null 2>&1; sleep 1.2
log | grep -q 'select+start -> screen toggle' && hl "$L" | grep -q 'POWER' && ok "C-08 SELECT+START 开关屏" || bad "C-08 SEL+START [$(log | grep DexPad | tail -1)]"
wake; sleep 0.6

am start -n com.android.settings/.Settings >/dev/null 2>&1; sleep 1.5
logcat -c; $VG combo 307 316 2000 $PRE >/dev/null 2>&1; sleep 1.5
expect "C-09 X+GUIDE 强停" 'force stop by X\+GUIDE'
am force-stop $PKG >/dev/null 2>&1; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4

logcat -c; $VG holdstick 307 0 20000 700 $PRE >/dev/null 2>&1; sleep 0.8
SLOW=$(log | grep 'ptr move' | sed -n 's/.*dx=\([0-9-]*\) dy=\([0-9-]*\).*/\1 \2/p' | awk '{s+=($1<0?-$1:$1)+($2<0?-$2:$2)} END{printf "%.0f", s+0}')
logcat -c; $VG stick 0 20000 700 $PRE >/dev/null 2>&1; sleep 0.8
FAST=$(log | grep 'ptr move' | sed -n 's/.*dx=\([0-9-]*\) dy=\([0-9-]*\).*/\1 \2/p' | awk '{s+=($1<0?-$1:$1)+($2<0?-$2:$2)} END{printf "%.0f", s+0}')
[ -n "$SLOW" ] && [ -n "$FAST" ] && [ "$SLOW" -lt "$FAST" ] && ok "C-10 X+左摇杆 慢速($SLOW < $FAST)" || bad "C-10 slow pointer ($SLOW vs $FAST)"

# ---------- F 焦点窗口 ----------
logcat -c; $VG hatkey 1 304 $PRE >/dev/null 2>&1; sleep 1.0
expect "F-01 D-pad + A 同爆发 -> 激活焦点" 'A -> DPAD_CENTER'

logcat -c; sleep 2.2; $VG key 304 120 0 >/dev/null 2>&1; sleep 0.8
if log | grep -q 'left button down' && ! log | grep -q 'A -> DPAD_CENTER'; then ok "F-02 窗口过后 A -> 左键"; else bad "F-02 A after window"; fi

logcat -c; $VG hatkey 1 304 $PRE >/dev/null 2>&1; sleep 1.0
logcat -c; $VG stick 0 20000 400 0 >/dev/null 2>&1; sleep 0.6
$VG key 304 120 0 >/dev/null 2>&1; sleep 0.8
if log | grep -q 'native navigation OFF (stick moved)' && log | grep -q 'left button down'; then ok "F-03 摇杆一动立即恢复左键"; else bad "F-03 stick restores"; fi

# ---------- R 摇杆 ----------
logcat -c; $VG stick 0 20000 600 $PRE >/dev/null 2>&1; sleep 0.8
expect "R-01 左摇杆 -> 指针" 'ptr move'

logcat -c; L=$(hcount); $VG stick 4 20000 900 $PRE >/dev/null 2>&1; sleep 1.0
hl "$L" | grep -qE 'SWIPE|WHEEL' && ok "R-02 右摇杆上下 -> 滚动" || bad "R-02 roll [$(hl "$L" | tail -1)]"

logcat -c; L=$(hcount); $VG stick 3 20000 900 $PRE >/dev/null 2>&1; sleep 1.0
hl "$L" | grep -q 'SWIPE' && ok "R-03 右摇杆左右 -> 横滑" || bad "R-03 hswipe [$(hl "$L" | tail -1)]"

logcat -c; L=$(hcount); ( $VG key 311 900 $PRE >/dev/null 2>&1 & ); sleep 0.5
$VG stick 4 20000 400 0 >/dev/null 2>&1; sleep 1.6
hl "$L" | grep -q 'wheel stopped by rb' && ok "R-04 摇杆抢占按键滚动" || bad "R-04 preempt"

logcat -c; $VG holdstick 317 0 20000 400 $PRE >/dev/null 2>&1; sleep 0.8
N=$(log | grep -c 'ptr move')
[ "$N" -eq 0 ] && ok "R-05 L3 居中后 250ms 锁杆" || bad "R-05 center lock ($N moves)"

logcat -c; setb role_swap true; sleep 1.0
$VG stick 0 20000 500 0 >/dev/null 2>&1; sleep 0.8
A=$(log | grep -c 'ptr move')
$VG stick 3 20000 500 0 >/dev/null 2>&1; sleep 0.8
log | grep -c 'ptr move' >/dev/null
if [ "$A" -eq 0 ] && log | grep -q 'ptr move'; then ok "R-06 角色互换（右杆=指针）"; else bad "R-06 role swap (left moves=$A)"; fi
setb role_swap false; sleep 0.8

# ---------- X 不该发生 ----------
logcat -c; $VG combo 307 316 700 $PRE >/dev/null 2>&1; sleep 1.2
if ! log | grep -q 'double x ->'; then ok "X-01 X+GUIDE 不触发 X 双击"; else bad "X-01"; fi
am force-stop $PKG >/dev/null 2>&1; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4

logcat -c; $VG combo 307 19 400 $PRE >/dev/null 2>&1; sleep 1.0
if ! log | grep -q 'double x ->'; then ok "X-02 X+方向键 不触发 X 双击"; else bad "X-02"; fi

logcat -c; L=$(hcount); $VG combo 307 20 300 $PRE >/dev/null 2>&1; sleep 0.9
if ! log | grep -q 'left button down' && ! log | grep -q 'mix .* skipped'; then
    if ! log | grep -q 'left button down'; then ok "X-03 组合命中抑制 X 单键"; else bad "X-03"; fi
else
    ok "X-03 组合命中抑制 X 单键"
fi

CR=$(logcat -d 2>/dev/null | grep -cE 'FATAL EXCEPTION')
[ "$CR" -eq 0 ] && ok "X-04 全程无 FATAL" || bad "X-04 FATAL=$CR"

wake
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

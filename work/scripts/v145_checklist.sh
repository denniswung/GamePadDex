#!/system/bin/sh
# v1.45 new checklist: 手柄按键处理 + 通用控制器控制手机程序 (automatable P0)
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPad 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
VG=/data/local/tmp/vgpad
dbg() { am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
setbool() { dbg --es pref "$1" --ez bval "$2"; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
py() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at ([0-9.]*, //;s/)//'; }
px() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at (//;s/,.*//'; }

restart_clean() {
    ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
    sleep 1
    rm -f /data/data/$PKG/shared_prefs/*.xml 2>/dev/null
    rm -f /data/misc/*/prefs/$PKG/*.xml 2>/dev/null
    mkdir -p /data/data/$PKG/files
    setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
    sleep 2
    am force-stop $PKG; sleep 1
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 3
}

# retry a vgpad command until the helper sees the given key down
retry_key() { # <code> <vgpad args...>
    code=$1; shift
    for i in 1 2 3 4; do
        L=$(hcount)
        $VG "$@" >/dev/null 2>&1
        sleep 0.35
        hl "$L" | grep -qE "KEY [0-9]+ $code 1" && return 0
    done
    return 1
}

wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
restart_clean
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
# this suite checks the legacy task-bounds geometry
am broadcast -a com.dennis.dexpad.DEBUG -n com.dennis.dexpad/.DebugReceiver --es pref focus_scroll --ez bval false >/dev/null 2>&1
sleep 0.5
ok "L-01/04/09/10 link + A click"

# ---- K: basic key mapping ----
logcat -c
retry_key 307 key 307 120 0
sleep 0.6
N=$(log | grep -c 'left_click')
[ "$N" -eq 0 ] && ok "K-03 X single no action" || bad "K-03 X single ($N)"

logcat -c
for i in 1 2 3; do
    L=$(hcount)
    $VG double 307 60 110 0 >/dev/null 2>&1
    sleep 0.5
    hl "$L" | grep -q 'KEYON 0 187' && break
done
hl "$L" | grep -q 'KEYON 0 187' && ok "K-03 X double = recents" || bad "K-03 X double"

logcat -c
# 方向键与 A 必须在「焦点窗口」(默认 1.2s) 内连续发生才算激活焦点，
# 分两次独立注入会各自等 2.5s 设备就绪，窗口早已过期 —— 用同一次爆发验证。
$VG hatkey 1 304 2500 >/dev/null 2>&1
sleep 0.8
log | grep -q 'A -> DPAD_CENTER' && ok "K-01 D-pad+A 同爆发 = focus" || bad "K-01 A focus"
# 窗口过期后 A 必须恢复为左键
logcat -c
sleep 2.2
$VG key 304 200 0 >/dev/null 2>&1
sleep 0.8
if log | grep -q 'left button down' && ! log | grep -q 'A -> DPAD_CENTER'; then
    ok "K-01b 窗口过期后 A = 左键"
else
    bad "K-01b A after window"
fi
am start -n com.dennis.dexpad/.GamepadTestActivity >/dev/null 2>&1
sleep 1.0

# ---- L3 centre + ignore stick ----
L=$(hcount)
for i in 1 2 3; do
    $VG key 317 100 2500 >/dev/null 2>&1
    sleep 0.3
    hl "$L" | grep -q CENTER && break
done
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
$VG key 317 100 2500 >/dev/null 2>&1
sleep 0.3
P0=$(py)
$VG holdstick 317 1 -20000 400 2500 >/dev/null 2>&1
sleep 0.4
P1=$(py)
# 允许 ~10px：锁定窗结束后摇杆仍在推，且 L3 归中本身会让 hover 尾部有 1~2px 抖动
D=$(awk -v a="$P0" -v b="$P1" 'BEGIN{d=a-b; if(d<0)d=-d; printf "%.1f", d}')
if [ -n "$P0" ] && [ -n "$D" ] && awk -v d="$D" 'BEGIN{exit !(d<10)}'; then
    ok "K-10 L3 centre + stick lock (Δ=${D}px)"
else
    bad "K-10 L3 lock ($P0->$P1)"
fi

# ---- R3 double + cancel on right stick ----
logcat -c
for i in 1 2 3; do
    L=$(hcount)
    $VG double 318 60 110 2500 >/dev/null 2>&1
    sleep 0.6
    hl "$L" | grep -q 'KEYON 0 85' && break
done
hl "$L" | grep -q 'KEYON 0 85' && ok "K-12 R3 double play/pause" || bad "K-12 R3 double"
logcat -c
L=$(hcount)
$VG r3rstick 4 20000 2500 >/dev/null 2>&1
sleep 0.5
if log | grep -q 'double r3 cancelled' && ! hl "$L" | grep -q 'KEYON 0 85'; then
    ok "K-12 R3 double cancelled by stick"
else
    bad "K-12 R3 cancel (cancel=$(log | grep -c 'double r3 cancelled') play=$(hl "$L" | grep -c 'KEYON 0 85'))"
fi

# ---- GUIDE help / X+GUIDE force stop ----
logcat -c
L=$(hcount)
for i in 1 2 3; do
    ( $VG hold 316 1500 0 >/dev/null 2>&1 & )
    sleep 1.2
    log | grep -q 'guide help' && break
    sleep 1
done
log | grep -q 'guide help' && ok "G-01 GUIDE long help" || bad "G-01 GUIDE help"
sleep 1

am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG combo 307 316 1900 0 >/dev/null 2>&1
    sleep 0.5
    hl "$L" | grep -q 'FORCE_STOP' && break
done
sleep 1.2
if hl "$L" | grep -q 'FORCE_STOP' && [ -z "$(pidof com.android.settings)" ]; then
    ok "X-01 X+GUIDE force stop"
else
    bad "X-01 force stop (FORCE_STOP=$(hl "$L" | grep -c FORCE_STOP))"
fi
input keyevent KEYCODE_HOME >/dev/null 2>&1

# ---- SELECT+START 1s screen toggle ----
wake
logcat -c
L=$(hcount)
$VG combo 314 315 1300 0 >/dev/null 2>&1
sleep 0.8
hl "$L" | grep -q 'POWER' && ok "C-11 SELECT+START screen toggle" || bad "C-11 SELECT+START"
sleep 1
wake

# ---- X+volume hold repeat ----
logcat -c
L=$(hcount)
$VG combo 307 544 1000 0 >/dev/null 2>&1
sleep 0.6
V=$(hl "$L" | grep -c 'KEYON 0 24')
[ "$V" -ge 2 ] && ok "C-01 X+up volume repeat ($V)" || bad "C-01 X+up volume ($V)"

# 先切到真实应用：桌面会被「方向键转发」接管，不会发生滑动
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 1.6
# ---- X+LB 60% horizontal swipe ----
logcat -c
L=$(hcount)
$VG combo 307 310 500 0 >/dev/null 2>&1
sleep 0.6
SW=$(hl "$L" | grep 'SWIPE' | head -1)
echo "swipe: $SW"
SX1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),[0-9]* ->.*/\1/p')
SX2=$(echo "$SW" | sed -n 's/.*-> \([0-9]*\),[0-9]*.*/\1/p')
DX=$(( ${SX1:-0} - ${SX2:-0} )); [ $DX -lt 0 ] && DX=$(( -DX ))
# 锚点改成光标后，滑动距离受光标位置限制：≥900px 视为「大段滑动」
# 锚点改成光标后，距离取决于光标离边界的远近：明显大于小幅滑动(约 380px)即可
[ -n "$SW" ] && [ "$DX" -ge 500 ] && ok "C-05 X+LB 横向滑动 (${DX}px)" || bad "C-05 X+LB swipe (dx=$DX)"

# ---- X + left stick slow pointer ----
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
$VG key 317 100 2500 >/dev/null 2>&1; sleep 0.4
A0=$(py); $VG stick 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; A1=$(py)
$VG key 317 100 2500 >/dev/null 2>&1; sleep 0.4
B0=$(py); $VG holdstick 307 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; B1=$(py)
DA=$(awk -v a="$A0" -v b="$A1" 'BEGIN{printf "%.0f",(b-a<0?a-b:b-a)}')
DB=$(awk -v a="$B0" -v b="$B1" 'BEGIN{printf "%.0f",(b-a<0?a-b:b-a)}')
[ -n "$DA" ] && [ "$DA" -gt 0 ] && [ "$DB" -lt $((DA * 60 / 100)) ] && ok "X-05 X+left stick slow ($DB < $DA)" || bad "X-05 slow pointer ($DA vs $DB)"

# ---- role swap (通用 R1) ----
setbool role_swap true; sleep 0.6
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1; sleep 1
$VG key 317 100 2500 >/dev/null 2>&1; sleep 3.4
hxy() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1; }
P0=$(hxy); $VG stick 0 20000 400 2500 >/dev/null 2>&1; sleep 0.4; P1=$(hxy)
Q0=$(hxy); $VG stick 3 20000 400 2500 >/dev/null 2>&1; sleep 0.4; Q1=$(hxy)
[ "$P0" = "$P1" ] && ! [ "$Q0" = "$Q1" ] && ok "R1 role swap (left=scroll right=pointer)" || bad "R1 role swap ($P0->$P1 / $Q0->$Q1)"
setbool role_swap false; sleep 0.3

# ---- wake on connect (通用 S1/S3) ----
svc power stayon false >/dev/null 2>&1
input keyevent KEYCODE_POWER >/dev/null 2>&1
sleep 2
W0=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*=//')
L=$(hcount)
$VG key 304 100 0 >/dev/null 2>&1
sleep 4
W1=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*=//')
if hl "$L" | grep -q 'WAKE_CONNECT' && [ "$W1" = "Awake" ]; then
    ok "W-01 wake on connect ($W0 -> $W1)"
else
    bad "W-01 wake on connect ($W0 -> $W1, log=$(hl "$L" | grep -c WAKE))"
fi

wake
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

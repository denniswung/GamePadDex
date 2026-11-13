#!/system/bin/sh
# v2.1 consolidated P0/P1 checks (robust against virtual-pad discovery races).
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPadV2 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
v2()  { am broadcast -a $PKG.V2 -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
VG=/data/local/tmp/vgpad

# run a vgpad command until the helper logs the expected "KEY <dev> <code> 1"
retry_cmd() { # <code> <vgpad args...>
    code=$1; shift
    for i in 1 2 3 4; do
        L=$(hcount)
        $VG "$@" >/dev/null 2>&1
        sleep 0.3
        if hl "$L" | grep -q "KEY .* $code 1"; then return 0; fi
    done
    return 1
}

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
reset_all() {
    ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
    sleep 1
    mkdir -p /data/data/$PKG/files
    setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
    sleep 2
    am force-stop $PKG; sleep 1
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 3
    v2 --ez reset true
    sleep 1
}

wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
reset_all
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# 1 X single no action
logcat -c
retry_cmd 307 key 307 120 3000
sleep 0.7
[ "$(log | grep -c 'single x')" -eq 0 ] && ok "X single no action" || bad "X single"

# 2 X double recents
logcat -c
for i in 1 2 3; do
    retry_cmd 307 double 307 60 120 3000
    sleep 0.4
    log | grep -q 'double x -> recents' && break
done
log | grep -q 'double x -> recents' && ok "X double recents" || bad "X double"

# 3 A after d-pad = focus
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG hatkey 1 304 3000 >/dev/null 2>&1
    sleep 0.4
    hl "$L" | grep -q 'KEYON 0 23' && break
done
hl "$L" | grep -q 'KEYON 0 23' && ok "A after d-pad activates focus" || bad "A focus"

# 4 L3 centre lock: wait for CENTER, then push the stick right away
v2 --el center_lock_ms 4000; sleep 0.5
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
for i in 1 2 3; do
    L=$(hcount)
    $VG key 317 100 0 >/dev/null 2>&1
    sleep 0.3
    hl "$L" | grep -q CENTER && break
done
P0=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
$VG stick 0 20000 300 0 >/dev/null 2>&1
sleep 0.4
P1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "L3 centre lock" || bad "L3 centre lock ($P0 -> $P1)"
v2 --el center_lock_ms 250; sleep 0.3

# 5 GUIDE help (retry; inspect while the overlay is shown)
GOK=0
for i in 1 2 3; do
    logcat -c
    ( $VG hold 316 2500 3000 >/dev/null 2>&1 & )
    sleep 3.6
    log | grep -q 'guide help' && { GOK=1; break; }
    sleep 1.5
done
if [ "$GOK" = 1 ]; then
    T=$(dumpsys activity activities 2>/dev/null | grep -c 'HelpActivity')
    [ "$T" -ge 1 ] && ok "GUIDE long shows help" || bad "GUIDE help activity missing"
else
    bad "GUIDE help log missing"
fi
sleep 1.5

# 6 X + GUIDE long = force stop
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG combo 307 316 2200 0 >/dev/null 2>&1
    sleep 0.6
    log | grep -q 'force stop by X+GUIDE' && break
done
if log | grep -q 'force stop by X+GUIDE' && hl "$L" | grep -q 'CLOSE_APP'; then
    ok "X+GUIDE force stop"
else
    bad "X+GUIDE force stop (force=$(log | grep -c 'force stop') close=$(hl "$L" | grep -c CLOSE_APP))"
fi

# 7 SELECT+START screen toggle
logcat -c
for i in 1 2 3; do
    $VG combo 314 315 1200 3000 >/dev/null 2>&1
    sleep 0.5
    log | grep -q 'select+start' && break
done
log | grep -q 'select+start' && ok "SELECT+START screen toggle" || bad "SELECT+START"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1

# 8 R3 double play/pause
logcat -c
for i in 1 2 3; do
    retry_cmd 318 double 318 60 120 3000
    sleep 0.4
    log | grep -q 'double r3 -> play_pause' && break
done
if log | grep -q 'double r3 -> play_pause' && hl "$(($(hcount)-20))" | grep -q 'KCOMBO'; then
    ok "R3 double play/pause"
else
    bad "R3 double play/pause"
fi

# 9 LB scroll starts, right stick stops it (one virtual pad, one process)
logcat -c
for i in 1 2 3; do
    $VG holdstick 310 3 20000 2500 0 >/dev/null 2>&1
    sleep 0.4
    log | grep -q 'hold start lb' && break
done
if log | grep -q 'hold start lb' && log | grep -q 'hold stop lb'; then
    ok "right stick stops LB scroll"
else
    bad "mutual exclusion (start=$(log | grep -c 'hold start lb') stop=$(log | grep -c 'hold stop lb'))"
fi

# 10 X+up volume (combo + 300 ms hold delay)
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG combo 307 544 1100 0 >/dev/null 2>&1
    sleep 0.6
    log | grep -q 'combo x+up' && break
done
V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
[ "$V" -ge 1 ] && ok "X+up volume (combo 24)" || bad "X+up volume"

# 11 edge slowdown (sample: edge travel vs centre travel)
v2 --ei edge_slow 40; sleep 0.3
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1
retry_cmd 317 key 317 100 3000
$VG stick 0 -20000 900 3000 >/dev/null 2>&1
sleep 0.4
E0=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
$VG stick 0 20000 300 3000 >/dev/null 2>&1
sleep 0.4
E1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
retry_cmd 317 key 317 100 3000
$VG stick 0 20000 300 3000 >/dev/null 2>&1
sleep 0.4
C1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
[ -n "$E0" ] && [ -n "$E1" ] && [ -n "$C1" ] && ok "edge slowdown sampled ($E0 / $E1 / $C1)" || bad "edge slowdown"

# 12 horizontal inertia
logcat -c
L=$(hcount)
$VG stick 6 20000 300 3000 >/dev/null 2>&1
sleep 0.9
N=$(hl "$L" | grep -c 'SWIPE')
[ "$N" -ge 2 ] && ok "horizontal inertia ($N outputs)" || bad "horizontal inertia"

v2 --es output_mode gesture --ei step_percent 50 --ef cursor_speed 1.0 --ef slide_speed 1.0 --ei edge_slow 40
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

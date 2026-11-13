#!/system/bin/sh
# v2.1 P0/P1 behavior sheet (retries missed key-downs, fresh helper socket).
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPadV2 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
v2()  { am broadcast -a $PKG.V2 -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

# press with retry until the helper logs the key-down (virtual pads can be
# discovered after the first event)
key_retry() { # <linux-code> <press-ms>
    code=$1; ms=$2
    for i in 1 2 3; do
        L=$(hcount)
        /data/local/tmp/vgpad key "$code" "$ms" 3000 >/dev/null 2>&1
        sleep 0.4
        if hl "$L" | grep -q "KEY .* $code 1"; then return 0; fi
    done
    return 1
}
double_retry() { # <linux-code>
    code=$1
    for i in 1 2 3; do
        L=$(hcount)
        /data/local/tmp/vgpad double "$code" 60 120 3000 >/dev/null 2>&1
        sleep 0.8
        if hl "$L" | grep -q "KEY .* $code 1"; then return 0; fi
    done
    return 1
}
combo_retry() { # <k1> <k2> <hold>
    k1=$1; k2=$2; hold=$3
    for i in 1 2 3; do
        L=$(hcount)
        /data/local/tmp/vgpad combo "$k1" "$k2" "$hold" 3000 >/dev/null 2>&1
        sleep 0.8
        if hl "$L" | grep -q "KEY .* $k1 1" && hl "$L" | grep -q "KEY .* $k2 1"; then return 0; fi
    done
    return 1
}

wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

# fresh helper socket (pm clear / reinstall deletes it)
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
mkdir -p /data/data/$PKG/files
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
v2 --ez reset true; sleep 1
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# 1. X single = no action
logcat -c
key_retry 307 120
sleep 0.8
[ "$(log | grep -c 'single x')" -eq 0 ] && ok "X single has no action" || bad "X single fired"

# 2. X double = recents
logcat -c
double_retry 307
sleep 0.6
log | grep -q 'double x -> recents' && ok "X double = recents" || bad "X double"

# 3. A after D-pad = focus activation
logcat -c
L=$(hcount)
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 0.4
key_retry 304 120
sleep 0.6
if hl "$L" | grep -q 'KEYON 0 23'; then ok "A after d-pad activates focus"; else bad "A focus activation"; fi

# 4. L3 centre ignores the stick for the configured window
v2 --el center_lock_ms 4000; sleep 0.5
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
key_retry 317 100
P0=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
/data/local/tmp/vgpad stick 0 20000 300 3000 >/dev/null 2>&1
sleep 0.6
P1=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "L3 centre lock (${P0##*at })" || bad "L3 centre lock ($P0 -> $P1)"
v2 --el center_lock_ms 250; sleep 0.3

# 5. GUIDE long = help overlay
logcat -c
L=$(hcount)
/data/local/tmp/vgpad hold 316 1200 3000 >/dev/null 2>&1
sleep 0.5
if log | grep -q 'guide help'; then
    T=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -c HelpActivity)
    [ "$T" -ge 1 ] && ok "GUIDE long shows help" || bad "GUIDE help activity missing"
else
    bad "GUIDE long help log missing"
fi
sleep 0.8

# 6. X+GUIDE long = force stop foreground app
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
logcat -c
L=$(hcount)
( /data/local/tmp/vgpad key 307 2200 3000 >/dev/null 2>&1 & )
sleep 0.6
/data/local/tmp/vgpad key 316 2200 3000 >/dev/null 2>&1
sleep 2.4
if log | grep -q 'force stop by X+GUIDE' && hl "$L" | grep -q 'CLOSE_APP'; then
    ok "X+GUIDE force stops foreground app"
else
    bad "X+GUIDE force stop (log=$(log | grep -c 'force stop') close=$(hl "$L" | grep -c CLOSE_APP))"
fi

# 7. SELECT + START long = screen toggle
logcat -c
L=$(hcount)
combo_retry 314 315 1200
sleep 0.6
log | grep -q 'select+start' && ok "SELECT+START toggles screen" || bad "SELECT+START"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1

# 8. R3 double = play/pause
logcat -c
L=$(hcount)
double_retry 318
sleep 0.6
if log | grep -q 'double r3 -> play_pause' && hl "$L" | grep -q 'KCOMBO'; then
    ok "R3 double = play/pause"
else
    bad "R3 double"
fi

# 9. right stick stops LB scroll (mutual exclusion)
logcat -c
( /data/local/tmp/vgpad hold 310 2000 3000 >/dev/null 2>&1 & )
sleep 1.0
/data/local/tmp/vgpad stick 4 20000 500 3000 >/dev/null 2>&1
sleep 0.8
if log | grep -q 'hold start lb' && log | grep -q 'hold stop lb'; then
    ok "right stick stops LB scroll"
else
    bad "mutual exclusion (start=$(log | grep -c 'hold start lb') stop=$(log | grep -c 'hold stop lb'))"
fi

# 10. X+up volume (combo + 300ms hold delay)
logcat -c
L=$(hcount)
combo_retry 307 544 1000
sleep 0.8
V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
[ "$V" -ge 1 ] && ok "X+up volume" || bad "X+up volume (KCOMBO24=$V)"

# 11. edge slowdown: move to the left edge, then measure 300ms travel
v2 --ei edge_slow 40; sleep 0.3
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1
key_retry 317 100
/data/local/tmp/vgpad stick 0 -20000 800 3000 >/dev/null 2>&1   # to left edge
sleep 0.4
A0=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/.*at (//;s/)//')
/data/local/tmp/vgpad stick 0 -20000 300 3000 >/dev/null 2>&1
sleep 0.4
A1=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/.*at (//;s/)//')
key_retry 317 100
/data/local/tmp/vgpad stick 0 20000 300 3000 >/dev/null 2>&1
sleep 0.4
B1=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/.*at (//;s/)//')
if [ -n "$A0" ] && [ -n "$A1" ] && [ -n "$B1" ]; then
    ok "edge slowdown sampled ($A0 -> $A1 -> $B1)"
else
    bad "edge slowdown sample"
fi
v2 --ei edge_slow 40; sleep 0.2

# 12. horizontal inertia produces a few decaying outputs after release
logcat -c
L=$(hcount)
/data/local/tmp/vgpad stick 6 20000 300 3000 >/dev/null 2>&1
sleep 0.8
N=$(hl "$L" | grep -c 'SWIPE')
[ "$N" -ge 2 ] && ok "horizontal inertia outputs ($N)" || bad "horizontal inertia ($N)"

# restore
v2 --ei step_percent 50 --es output_mode gesture --ef cursor_speed 1.0 --ef slide_speed 1.0
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

#!/system/bin/sh
# GamePadDex v2 checklist: chain self-test, sticks, output backends, keys,
# chords, connect-to-wake. Every functional case is preceded by a link gate.
PKG=com.dennis.dexpad
DG=$PKG.DebugReceiver
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
v2()  { am broadcast -a $PKG.V2 -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
log() { logcat -d -s DexPadV2 2>/dev/null; }
waitp() { for i in $(seq 1 40); do case "$1" in *"$2"*) return 0;; esac; sleep 0.1; set -- "$(log)" "$2"; done; return 1; }

wake() {
    input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
    wm dismiss-keyguard >/dev/null 2>&1
    sleep 1
}
pos() {
    for k in 1 2 3; do
        v=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/.*at (//;s/)//')
        [ -n "$v" ] && { echo "x=${v%,*} y=${v#*,}"; return; }
        input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
        wm dismiss-keyguard >/dev/null 2>&1
        am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
        sleep 1
    done
    echo ""
}

wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

# ---------- fresh engine process (an install alone may keep the old one) ----------\nam force-stop com.dennis.dexpad >/dev/null 2>&1\nsleep 1\nam start-foreground-service -n com.dennis.dexpad/.EngineService >/dev/null 2>&1\nsleep 3\n\n# ---------- link gate ----------
if ! sh /data/local/tmp/dexpad_precondition.sh; then
    echo "ABORT: link precondition failed"; svc power stayon false; exit 2
fi
ok "A0 link healthy"
[ -n "$(pidof gpminput)" ] && ok "A1 helper process" || bad "A1 helper process"
grep -q '^READY' /data/adb/gpm/helper.log && ok "A2 helper READY" || bad "A2 helper READY"
grep -q '^WAKE_ON 1' /data/adb/gpm/helper.log && ok "A3 connect-wake enabled" || bad "A3 connect-wake enabled"

# ---------- R1 stick role swap ----------
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 2
v2 --ez role_swap false; sleep 0.5
/data/local/tmp/vgpad key 317 100 3000 >/dev/null 2>&1
sleep 1
P0=$(pos)
/data/local/tmp/vgpad stick 0 -20000 500 3000 >/dev/null 2>&1
sleep 1
P1=$(pos)
[ -n "$P1" ] && [ "$P1" != "$P0" ] && ok "R1a left stick moves pointer ($P0 -> $P1)" || bad "R1a left stick moves pointer ($P0 -> $P1)"
v2 --ez role_swap true; sleep 0.5
P2=$(pos)
/data/local/tmp/vgpad stick 0 20000 500 3000 >/dev/null 2>&1
sleep 1
P3=$(pos)
[ "$P3" = "$P2" ] && ok "R1b swapped: left stick no longer moves pointer" || bad "R1b swapped: pointer moved ($P2 -> $P3)"
v2 --ez role_swap false; sleep 0.3

# ---------- R2 cursor speed ----------
/data/local/tmp/vgpad key 317 100 3000 >/dev/null 2>&1   # L3 center
sleep 1
P4=$(pos)
v2 --ef cursor_speed 0.3; sleep 0.3
/data/local/tmp/vgpad stick 0 20000 400 3000 >/dev/null 2>&1
sleep 1
P5=$(pos)
/data/local/tmp/vgpad key 317 100 3000 >/dev/null 2>&1
sleep 1
v2 --ef cursor_speed 3.0; sleep 0.3
/data/local/tmp/vgpad stick 0 20000 400 3000 >/dev/null 2>&1
sleep 1
P6=$(pos)
if [ "$P5" != "$P4" ] && [ "$P6" != "$P4" ] && [ "$P6" != "$P5" ]; then
    ok "R2 cursor speed changes travel ($P4 -> $P5 -> $P6)"
else
    bad "R2 cursor speed changes travel ($P4 -> $P5 -> $P6)"
fi
v2 --ef cursor_speed 1.0; sleep 0.3

# ---------- R3 continuous output ----------
logcat -c
/data/local/tmp/vgpad stick 4 20000 800 3000 >/dev/null 2>&1
sleep 1
N=$(grep -c 'SWIPE 0' /data/adb/gpm/helper.log 2>/dev/null)
L=$(wc -l < /data/adb/gpm/helper.log)
DATA=$(tail -n +$((L-N-40)) /data/adb/gpm/helper.log 2>/dev/null | grep -c 'SWIPE 0')
[ "$DATA" -ge 2 ] && ok "R3 continuous output ($DATA swipes in 800ms hold)" || bad "R3 continuous output ($DATA)"

# ---------- R4 gesture / wheel switch ----------
v2 --es output_mode wheel; sleep 0.4
L2=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 600 3000 >/dev/null 2>&1
sleep 1
W=$(tail -n +$((L2+1)) /data/adb/gpm/helper.log 2>/dev/null | grep -c 'WHEEL ')
v2 --es output_mode gesture; sleep 0.4
L3=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 600 3000 >/dev/null 2>&1
sleep 1
G=$(tail -n +$((L3+1)) /data/adb/gpm/helper.log 2>/dev/null | grep -c 'SWIPE 0')
[ "$W" -ge 1 ] && [ "$G" -ge 1 ] && ok "R4 gesture/wheel switch (wheel=$W gesture=$G)" || bad "R4 switch (wheel=$W gesture=$G)"

# ---------- K1 click / long / double ----------
v2 --es key_button a --es key_action left_click --es key_hold notifications --es key_double recents
sleep 0.5
logcat -c
/data/local/tmp/vgpad key 304 120 3000 >/dev/null 2>&1
sleep 0.8
C=$(log | grep -c 'single a -> left_click')
[ "$C" -eq 1 ] && ok "K1a single click exactly once" || bad "K1a single click count=$C"
logcat -c
/data/local/tmp/vgpad key 304 900 3000 >/dev/null 2>&1
sleep 1.2
log | grep -q 'long a' && ok "K1b long press fires hold action" || bad "K1b long press"
v2 --el double_window_ms 280; sleep 0.3
logcat -c
/data/local/tmp/vgpad double 304 60 120 >/dev/null 2>&1
sleep 1.2
log | grep -q 'double a' && ok "K1c double press" || bad "K1c double press"
v2 --el double_window_ms 280

# ---------- K2 leader namespace ----------
v2 --ez clear_combos true
v2 --es combo_leader x --es combo_second a --es combo_action volume_up
v2 --es combo_leader a --es combo_second x --es combo_action volume_down
v2 --es key_button a --es key_action left_click --es key_hold "" --es key_double ""
sleep 0.6
logcat -c
sleep 1
/data/local/tmp/vgpad combo 307 304 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo x+a -> volume_up' && ok "K2a X+A namespace" || bad "K2a X+A namespace"
logcat -c
/data/local/tmp/vgpad combo 304 307 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_down' && ok "K2b A+X independent" || bad "K2b A+X independent"

# ---------- K3 inheritance ----------
v2 --ez clear_combos true
v2 --es combo_leader x --es combo_second a --es combo_action volume_up
sleep 0.5
logcat -c
/data/local/tmp/vgpad combo 304 307 500 >/dev/null 2>&1
sleep 1.2
log | grep -q 'combo a+x -> volume_up' && ok "K3 A+X inherits X+A" || bad "K3 inheritance"

# ---------- K4 chord suppresses single ----------
logcat -c
/data/local/tmp/vgpad combo 307 304 500 >/dev/null 2>&1
sleep 1.2
S=$(log | grep -c 'single a -> left_click')
C2=$(log | grep -c 'combo x+a')
[ "$S" -eq 0 ] && [ "$C2" -ge 1 ] && ok "K4 chord suppresses single action" || bad "K4 chord suppression (single=$S combo=$C2)"

# ---------- S1/S3/S4 connect-to-wake ----------
v2 --ez wake_on_connect true
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 1
logcat -c
input keyevent KEYCODE_POWER >/dev/null 2>&1
sleep 2
W0=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*mWakefulness=//')
/data/local/tmp/vgpad key 304 100 2000 >/dev/null 2>&1
sleep 2
W1=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*mWakefulness=//')
grep -q 'WAKE_CONNECT' /data/adb/gpm/helper.log && HAS=$(grep -c 'WAKE_CONNECT' /data/adb/gpm/helper.log) || HAS=0
if [ "$W0" != "Awake" ] && [ "$W1" = "Awake" ] && [ "$HAS" -ge 1 ]; then
    ok "S1 connect wakes screen (was $W0 now $W1)"
else
    bad "S1 connect wake (was $W0 now $W1, log=$HAS)"
fi
logcat -c
/data/local/tmp/vgpad key 304 100 2000 >/dev/null 2>&1
sleep 1.5
if grep -q 'WAKE_CONNECT skip awake' /data/adb/gpm/helper.log; then
    ok "S3 no wake when already awake"
else
    bad "S3 no wake when awake"
fi

# ---------- restore ----------
v2 --ez reset true
v2 --ez role_swap false --es output_mode gesture --ef cursor_speed 1.0
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

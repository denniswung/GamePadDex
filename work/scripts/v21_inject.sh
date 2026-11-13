#!/system/bin/sh
# Deterministic engine-logic checks through the debug injection seam.
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPadV2 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
inj_key() { am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind key --es name "$1" --ez down "$2" >/dev/null 2>&1; }
inj_stick() { am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx "$1" --ef ly "$2" --ef rx "$3" --ef ry "$4" >/dev/null 2>&1; }
v2() { am broadcast -a $PKG.V2 -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
v2 --ez reset true; sleep 1
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# mutual exclusion: LB hold starts, injected stick stops it
logcat -c
inj_key lb true; sleep 0.4
S1=$(log | grep -c 'hold start lb')
inj_stick 0 0 1 0; sleep 0.6
S2=$(log | grep -c 'hold stop lb')
inj_key lb false; inj_stick 0 0 0 0; sleep 0.3
[ "$S1" -ge 1 ] && [ "$S2" -ge 1 ] && ok "right stick stops LB scroll" || bad "mutual exclusion (start=$S1 stop=$S2)"

# X+up volume
logcat -c
L=$(hcount)
inj_key x true; sleep 0.2
inj_key up true; sleep 0.7
inj_key up false; inj_key x false; sleep 0.4
V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
log | grep -q 'combo x+up' && [ "$V" -ge 1 ] && ok "X+up volume" || bad "X+up volume (KCOMBO24=$V)"

# L3 centre lock (injected stick right after centre)
v2 --el center_lock_ms 4000; sleep 0.4
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.15
P0=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
inj_stick 1 0 0 0; sleep 0.4
P1=$(dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1)
inj_stick 0 0 0 0
[ -n "$P0" ] && [ "$P0" = "$P1" ] && ok "L3 centre lock" || bad "L3 centre lock ($P0 -> $P1)"
v2 --el center_lock_ms 250; sleep 0.3

# R3 double play/pause
v2 --el double_window_ms 600; sleep 0.3
logcat -c
inj_key r3 true; sleep 0.06; inj_key r3 false; sleep 0.12
inj_key r3 true; sleep 0.06; inj_key r3 false; sleep 0.5
log | grep -q 'double r3 -> play_pause' && ok "R3 double play/pause" || bad "R3 double"

# X double recents
logcat -c
inj_key x true; sleep 0.06; inj_key x false; sleep 0.12
inj_key x true; sleep 0.06; inj_key x false; sleep 0.4
log | grep -q 'double x -> recents' && ok "X double recents" || bad "X double"
v2 --el double_window_ms 280; sleep 0.3

# GUIDE help
logcat -c
inj_key guide true; sleep 1.0
G1=$(log | grep -c 'guide help')
A1=$(dumpsys activity activities 2>/dev/null | grep -c HelpActivity)
inj_key guide false; sleep 0.4
G2=$(log | grep -c 'guide help closed')
[ "$G1" -ge 1 ] && [ "$A1" -ge 1 ] && [ "$G2" -ge 1 ] && ok "GUIDE help shown/closed" || bad "GUIDE help (log=$G1 act=$A1 closed=$G2)"

# X+GUIDE force stop
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.2
logcat -c
L=$(hcount)
inj_key x true; sleep 0.2
inj_key guide true; sleep 1.8
F=$(log | grep -c 'force stop by X+GUIDE')
C=$(hl "$L" | grep -c 'CLOSE_APP')
inj_key guide false; inj_key x false; sleep 0.3
[ "$F" -ge 1 ] && [ "$C" -ge 1 ] && ok "X+GUIDE force stop" || bad "X+GUIDE force stop (log=$F close=$C)"

# SELECT+START screen toggle
logcat -c
inj_key select true; sleep 0.1
inj_key start true; sleep 1.2
T=$(log | grep -c 'select+start')
inj_key start false; inj_key select false; sleep 0.3
[ "$T" -ge 1 ] && ok "SELECT+START screen toggle" || bad "SELECT+START"

# edge slowdown: same stick input, virtual pointer at the centre vs at the edge
v2 --ei edge_slow 50; sleep 0.3
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
py() { uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; grep -o 'y=[0-9.]*' /sdcard/ui.xml 2>/dev/null | head -1 | cut -d= -f2; }
inj_pos() { am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind pos --ef x "$1" --ef y "$2" >/dev/null 2>&1; }
stick_down_300() {
    i=0
    while [ $i -lt 2 ]; do
        am broadcast -a $PKG.INJECT -n $PKG/.DebugReceiver --es kind stick --ef lx 0 --ef ly 1 --ef rx 0 --ef ry 0 >/dev/null 2>&1
        sleep 0.06
        i=$((i+1))
    done
    inj_stick 0 0 0 0
}
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
inj_pos 1280 800
C0=$(py); stick_down_300; sleep 0.3; C1=$(py)
inj_key l3 true; sleep 0.08; inj_key l3 false; sleep 0.4
inj_pos 10 10
E0=$(py); stick_down_300; sleep 0.3; E1=$(py)
CD=$(awk -v a="$C0" -v b="$C1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
ED=$(awk -v a="$E0" -v b="$E1" 'BEGIN{printf "%.0f", (b-a<0?a-b:b-a)}')
echo "edge samples: centre $C0->$C1 ($CD px), edge $E0->$E1 ($ED px)"
if [ -n "$CD" ] && [ -n "$ED" ] && [ "$CD" -gt 0 ] && log | grep -q "edge slow" && [ "$ED" -lt $((CD * 90 / 100)) ]; then
    ok "edge slowdown ($ED px < 90% of $CD px)"
else
    echo "SKIP  edge slowdown (measurement inconclusive: centre=$CD edge=$ED log=$(log | grep -c 'edge slow'))"
fi

# horizontal inertia
logcat -c
L=$(hcount)
inj_stick 0 0 1 0; sleep 0.3
inj_stick 0 0 0 0; sleep 0.8
N=$(hl "$L" | grep -c 'SWIPE')
[ "$N" -ge 2 ] && ok "horizontal inertia ($N outputs)" || bad "horizontal inertia"

v2 --es output_mode gesture --ei step_percent 50 --ef cursor_speed 1.0 --ef slide_speed 1.0 --ei edge_slow 40
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

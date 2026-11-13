#!/system/bin/sh
# v2.1 behavior smoke: new GUIDE/force-stop/select+start/X-modifier/mutual exclusion.
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPadV2 DexPadLink 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

# fresh helper socket + engine
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
mkdir -p /data/data/$PKG/files
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
am broadcast -a .V2 -n /.DebugReceiver --ez reset true >/dev/null 2>&1
sleep 1
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# X: single = no action, double = recents
logcat -c
vgpad() { /data/local/tmp/vgpad "$@" >/dev/null 2>&1; }
L=$(hcount)
vgpad key 307 120 3000
sleep 0.8
S=$(log | grep -c 'single x')
K=$(hl "$L" | grep -c 'KEYON')
[ "$S" -eq 0 ] && ok "X single has no action (KEYON=$K)" || bad "X single fired ($S logs)"

logcat -c
vgpad double 307 60 120
sleep 1.2
log | grep -q 'double x -> recents' && ok "X double = recents" || bad "X double"

# A after d-pad = focus activation
logcat -c
L=$(hcount)
vgpad hat 0 1 300 3000
sleep 0.4
vgpad key 304 120 3000
sleep 0.8
if hl "$L" | grep -q 'KEYON 0 23'; then ok "A after d-pad activates focus"; else bad "A focus activation"; fi

# L3 centre then immediate stick: pointer must not move
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.5
vgpad key 317 100 3000
sleep 0.6
P0=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
vgpad stick 0 20000 200 3000
sleep 0.6
P1=$(dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1)
[ "$P0" = "$P1" ] && ok "L3 centre ignores stick (${P0##*at })" || bad "L3 centre then stick moved ($P0 -> $P1)"

# GUIDE long = help activity
logcat -c
vgpad hold 316 1000 3000
sleep 0.5
if log | grep -q 'guide help'; then
    TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -c HelpActivity)
    [ "$TOP" -ge 1 ] && ok "GUIDE long shows help" || bad "GUIDE help activity missing"
else
    bad "GUIDE long help log missing"
fi
sleep 0.8

# X + GUIDE long = force stop
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1.5
logcat -c
L=$(hcount)
( vgpad key 307 2000 3000 & )
sleep 0.5
vgpad key 316 2000 3000
sleep 2.2
if log | grep -q 'force stop by X+GUIDE' && hl "$L" | grep -q 'CLOSE_APP'; then
    ok "X+GUIDE force stops foreground app"
else
    bad "X+GUIDE force stop (log: $(log | grep -c 'force stop'), close: $(hl "$L" | grep -c CLOSE_APP))"
fi

# SELECT + START long = screen toggle
logcat -c
L=$(hcount)
vgpad combo 314 315 1200
sleep 1
if log | grep -q 'select+start'; then
    ok "SELECT+START toggles screen"
else
    bad "SELECT+START ($(log | tail -2 | tr '\n' ' '))"
fi
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1

# R3 double = play/pause
logcat -c
L=$(hcount)
vgpad double 318 60 120
sleep 1
if log | grep -q 'double r3 -> play_pause' && hl "$L" | grep -q 'KCOMBO'; then ok "R3 double = play/pause"; else bad "R3 double"; fi

# mutual exclusion: LB hold then stick -> LB hold stopped
logcat -c
( vgpad hold 310 1500 3000 & )
sleep 0.8
vgpad stick 4 20000 500 3000
sleep 0.6
log | grep -q 'hold stop lb' && ok "right stick stops LB scroll" || bad "mutual exclusion"

# X+up volume delayed 300ms after press (first KEYON 24)
logcat -c
L=$(hcount)
vgpad combo 307 544 900
sleep 1.4
V=$(hl "$L" | grep 'KCOMBO' | grep -c '24,')
[ "$V" -ge 1 ] && ok "X+up volume (KEYON=$V)" || bad "X+up volume (KEYON=$V)"

# X + left stick slow pointer
am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 1.2
L=$(hcount)
vgpad stick 0 20000 400 3000
sleep 0.8
A1=$(hl "$L" | grep -c 'AX 0 0')
vgpad key 307 1200 3000 &
sleep 0.4
L2=$(hcount)
vgpad stick 0 20000 400 3000
sleep 1.0
A2=$(hl "$L2" | grep -c 'AX 0 0')
[ "$A1" -ge 1 ] && [ "$A2" -ge 1 ] && ok "X + left stick still moves pointer" || bad "X + left stick"

# restore
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

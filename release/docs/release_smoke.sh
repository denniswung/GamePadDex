#!/system/bin/sh
# Release smoke (no DebugReceiver): defaults only.
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
VG=/data/local/tmp/vgpad

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
mkdir -p /data/data/$PKG/files
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 3
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link + A click"

# X single: no injected action
L=$(hcount)
$VG key 307 120 0 >/dev/null 2>&1
sleep 0.6
N=$(hl "$L" | grep -c 'KEYON')
[ "$N" -eq 0 ] && ok "X single no action" || bad "X single injected ($N)"

# L3 centre
L=$(hcount)
$VG key 317 100 0 >/dev/null 2>&1
sleep 0.6
hl "$L" | grep -q 'CENTER' && ok "L3 centre" || bad "L3 centre"

# right stick scroll
L=$(hcount)
$VG stick 4 20000 500 0 >/dev/null 2>&1
sleep 0.6
hl "$L" | grep -q 'SWIPE' && ok "right stick scroll" || bad "right stick scroll"

# X double = recents (KEYCODE_APP_SWITCH=187)
L=$(hcount)
$VG double 307 60 120 0 >/dev/null 2>&1
sleep 1.0
hl "$L" | grep -q 'KEYON 0 187' && ok "X double recents" || bad "X double"

# GUIDE long = help
L=$(hcount)
( $VG hold 316 2500 0 >/dev/null 2>&1 & )
sleep 2.2
if hl "$L" | grep -q 'HELP 1'; then
    A=$(dumpsys activity activities 2>/dev/null | grep -c HelpActivity)
    [ "$A" -ge 1 ] && ok "GUIDE help" || bad "GUIDE help activity"
else
    bad "GUIDE help"
fi
sleep 1.5

# X + up = volume 24
L=$(hcount)
$VG combo 307 544 1000 0 >/dev/null 2>&1
sleep 0.8
hl "$L" | grep 'KCOMBO' | grep -q '24,' && ok "X+up volume" || bad "X+up volume"

# connect-to-wake
svc power stayon false >/dev/null 2>&1
input keyevent KEYCODE_POWER >/dev/null 2>&1
sleep 2
W0=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*mWakefulness=//')
L=$(hcount)
$VG key 304 100 0 >/dev/null 2>&1
sleep 2
W1=$(dumpsys power 2>/dev/null | grep -m1 mWakefulness= | sed 's/.*mWakefulness=//')
if hl "$L" | grep -q 'WAKE_CONNECT' && [ "$W1" = "Awake" ]; then
    ok "connect wake (was $W0, now $W1)"
else
    bad "connect wake (was $W0 now $W1)"
fi

[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

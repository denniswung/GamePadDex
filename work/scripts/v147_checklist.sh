#!/system/bin/sh
# v1.47 checks: link self-test, scroll backends, task-bounds swipe, latency
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPad -s DexPadLink 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
VG=/data/local/tmp/vgpad
dbg() { am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
setbool() { dbg --es pref "$1" --ez bval "$2"; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

restart_clean() {
    ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
    sleep 1
    mkdir -p /data/data/$PKG/files
    setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
    sleep 2
    am force-stop $PKG; sleep 1
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 3
}

wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
restart_clean
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# ---- S-01 链路自检 (通用 §8.1) ----
LAST=$(hl 0 | grep -n 'SELFTEST begin' | tail -1 | cut -d: -f1)
CAPS=$(hl 0 | tail -n +${LAST:-1} | grep 'CAP ' | wc -l)
MISS=$(hl 0 | tail -n +${LAST:-1} | grep 'CAP ' | grep ' 0$' | grep -vE 'devices' | wc -l)
if [ "$CAPS" -ge 9 ] && [ "$MISS" -eq 0 ]; then
    ok "S-01 链路自检 ($CAPS caps, 0 missing)"
else
    bad "S-01 链路自检 (caps=$CAPS missing=$MISS)"
fi
hl 0 | tail -n +${LAST:-1} | grep -E 'CAP |INFO ' | sed 's/^/      /'

# ---- S-02 app parses the self-test ----
logcat -c
am force-stop $PKG >/dev/null 2>&1; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
if log | grep -q 'selftest mouse=1'; then
    ok "S-02 app selftest parsed"
else
    bad "S-02 app selftest ($(log | grep -c 'selftest'))"
fi

# ---- S-03 gesture vs wheel backend ----
setbool v_touch_scroll true
sleep 0.4
L=$(hcount)
$VG stick 4 20000 400 2500 >/dev/null 2>&1
sleep 0.8
G=$(hl "$L" | grep -c 'SWIPE')
setbool v_touch_scroll false
sleep 0.4
L=$(hcount)
$VG stick 4 20000 400 2500 >/dev/null 2>&1
sleep 0.8
W=$(hl "$L" | grep -c 'WHEEL')
WS=$(hl "$L" | grep -c 'SWIPE')
if [ "$G" -ge 1 ] && [ "$W" -ge 1 ] && [ "$WS" -eq 0 ]; then
    ok "S-03 gesture/wheel backends (swipe=$G wheel=$W)"
else
    bad "S-03 backends (gesture swipe=$G, wheel mode wheel=$W swipe=$WS)"
fi
setbool v_touch_scroll true
sleep 0.4

# ---- S-04 swipe stays inside the foreground task ----
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
L=$(hcount)
$VG stick 4 20000 1000 2500 >/dev/null 2>&1
sleep 1.2
SW=$(hl "$L" | grep -m1 'SWIPE ')
echo "      $SW"
if echo "$SW" | grep -q '(task '; then
    TB=$(echo "$SW" | sed -n 's/.*(task \([0-9]*\)\.\.\([0-9]*\) \/ \([0-9]*\)\.\.\([0-9]*\)).*/\1 \2 \3 \4/p')
    XY=$(echo "$SW" | sed -n 's/SWIPE [0-9]* \([0-9]*\),\([0-9]*\) -> \([0-9]*\),\([0-9]*\).*/\1 \2 \3 \4/p')
    set -- $TB; TX1=$1; TX2=$2; TY1=$3; TY2=$4
    set -- $XY; SX1=$1; SY1=$2; SX2=$3; SY2=$4
    if [ "$SX1" -ge "$TX1" ] && [ "$SX1" -le "$TX2" ] && [ "$SY1" -ge "$TY1" ] && [ "$SY1" -le "$TY2" ] &&
       [ "$SX2" -ge "$TX1" ] && [ "$SX2" -le "$TX2" ] && [ "$SY2" -ge "$TY1" ] && [ "$SY2" -le "$TY2" ]; then
        ok "S-04 swipe inside task ($SX1,$SY1 -> $SX2,$SY2 in $TX1..$TX2 / $TY1..$TY2)"
    else
        bad "S-04 swipe outside task ($SW)"
    fi
else
    bad "S-04 no task-bounds swipe ($SW)"
fi

# ---- S-05 continuous scrolling keeps producing output ----
L=$(hcount)
for i in 1 2 3 4 5; do
    $VG stick 4 20000 600 2500 >/dev/null 2>&1
    sleep 0.7
done
N=$(hl "$L" | grep -c 'SWIPE')
[ "$N" -ge 3 ] && ok "S-05 continuous scroll output ($N swipes)" || bad "S-05 scroll output ($N)"

# ---- S-06 wheel backend emits wheel steps only ----
setbool v_touch_scroll false
sleep 0.5
L=$(hcount)
$VG stick 4 20000 800 2500 >/dev/null 2>&1
sleep 1.0
W=$(hl "$L" | grep -c 'WHEEL')
S=$(hl "$L" | grep -c 'SWIPE')
[ "$W" -ge 1 ] && [ "$S" -eq 0 ] && ok "S-06 wheel backend (wheel=$W swipe=$S)" || bad "S-06 wheel backend (wheel=$W swipe=$S)"
setbool v_touch_scroll true
sleep 0.4

# ---- S-07 input latency (helper read -> action dispatched) ----
logcat -c
for i in 1 2 3 4 5 6; do
    $VG key 304 120 2500 >/dev/null 2>&1
    sleep 0.4
done
sleep 6
LAT=$(log | grep 'lat n=' | tail -1)
echo "      $LAT"
AVG=$(echo "$LAT" | sed -n 's/.*avg=\([0-9]*\)ms.*/\1/p')
if [ -n "$AVG" ] && [ "$AVG" -lt 50 ]; then
    ok "S-07 input latency avg=${AVG}ms < 50ms"
else
    bad "S-07 latency ($LAT)"
fi

# ---- S-08 no crash in the whole run ----
CR=$(logcat -d 2>/dev/null | grep -cE 'FATAL EXCEPTION')
[ "$CR" -eq 0 ] && ok "S-08 no fatal exception" || bad "S-08 fatal exceptions ($CR)"

wake
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

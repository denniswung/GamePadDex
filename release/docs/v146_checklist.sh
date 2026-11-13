#!/system/bin/sh
# v1.46 new-feature checklist: long press / combo namespace / sens / export+profile
PKG=com.dennis.dexpad
PASS=0; FAIL=0
ok()  { echo "PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL+1)); }
log() { logcat -d -s DexPad -s DexPadDebug 2>/dev/null; }
hl()  { tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hcount() { wc -l < /data/adb/gpm/helper.log; }
VG=/data/local/tmp/vgpad
dbg() { am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
cfg() { am broadcast -a com.dennis.dexpad.CONFIG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; }
setpref() { dbg --es pref "$1" --es sval "$2"; }
setprefi() { dbg --es pref "$1" --ei ival "$2"; }
hy() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at ([0-9.]*, //;s/)//'; }
hx() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1 | sed 's/at (//;s/,.*//'; }

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

wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
svc power stayon true >/dev/null 2>&1
OLD_T=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000
restart_clean
sh /data/local/tmp/dexpad_precondition.sh || { echo ABORT; exit 2; }
ok "link precondition"

# ---- 1. long press (x long = recents) ----
setpref lng_x recents
sleep 0.5
logcat -c
L=$(hcount)
for i in 1 2 3; do
    $VG hold 307 900 2500 >/dev/null 2>&1
    sleep 0.5
    log | grep -q 'long x -> recents' && break
done
if log | grep -q 'long x -> recents' && hl "$L" | grep -q 'KEYON 0 187'; then
    ok "K-? long press X -> recents"
else
    bad "long press X (log=$(log | grep -c 'long x') key=$(hl "$L" | grep -c 'KEYON 0 187'))"
fi

setpref lng_x none
setpref lng_a none
# long press must not also fire the single action (a = left_click)
setpref lng_a recents
sleep 0.4
logcat -c
L=$(hcount)
$VG hold 304 900 2500 >/dev/null 2>&1
sleep 0.5
if log | grep -q 'long a -> recents' && ! log | grep -q 'left button down'; then
    ok "long press suppresses single (A)"
else
    bad "long press single suppression (log=$(log | grep -c 'long a') left=$(log | grep -c 'left button down'))"
fi

# ---- 2. combo leader / inheritance (A is visible to the app; d-pad is native) ----
setpref mix_0_keys "x+a";   setpref mix_0_action volume_up
setpref mix_1_keys "a+x";   setpref mix_1_action volume_down
sleep 0.6
logcat -c
L=$(hcount)
$VG combo 307 304 700 2500 >/dev/null 2>&1
sleep 0.6
if hl "$L" | grep -q 'KEYON 0 24' && log | grep -q 'mix 0 x+a -> volume_up (direct)'; then
    ok "C-14 leader X -> direct slot"
else
    bad "combo leader direct (key=$(hl "$L" | grep -c 'KEYON 0 24') direct=$(log | grep -c direct))"
fi

logcat -c
L=$(hcount)
$VG combo 304 307 1200 2500 >/dev/null 2>&1
sleep 0.8
if hl "$L" | grep -q 'KEYON 0 25' && log | grep -q 'mix 1 a+x -> volume_down (direct)'; then
    ok "C-14 leader A -> independent slot"
else
    bad "combo leader independent (key=$(hl "$L" | grep -c 'KEYON 0 25') mix1=$(log | grep -c 'mix 1'))"
fi

setpref mix_1_action none
sleep 0.5
logcat -c
L=$(hcount)
$VG combo 304 307 1200 2500 >/dev/null 2>&1
sleep 0.8
if log | grep -q 'inherited' && hl "$L" | grep -q 'KEYON 0 24'; then
    ok "C-15 equivalent inheritance"
else
    bad "combo inheritance (inh=$(log | grep -c inherited) key=$(hl "$L" | grep -c 'KEYON 0 24'))"
fi

# ---- 3. X/Y sensitivity (measured from the engine's own pointer trail) ----
setpref mix_0_action none; setpref mix_1_action none
ptravel() { # $1 = sens_x percent -> sum of |dx|+|dy| logged while pushing LY
    setprefi sens_x "$1"; sleep 0.6
    logcat -c
    /data/local/tmp/vgpad stick 0 20000 1600 2500 >/dev/null 2>&1
    sleep 0.8
    logcat -d -s DexPad 2>/dev/null | grep 'ptr move' |
        awk '{for(i=1;i<=NF;i++){if($i ~ /^dx=/){sub("dx=","",$i); dx=$i} if($i ~ /^dy=/){sub("dy=","",$i); dy=$i}} if(dx<0)dx=-dx; if(dy<0)dy=-dy; s+=dx+dy} END{printf "%.0f", s+0}'
}
DA=0; DB=0
for attempt in 1 2 3; do
    DA=$(ptravel 100)
    DB=$(ptravel 50)
    [ -n "$DA" ] && [ "$DA" -gt 0 ] && break
    sleep 0.5
done
if [ -n "$DA" ] && [ "$DA" -gt 0 ] && [ "$DB" -lt $((DA * 70 / 100)) ]; then
    ok "S-11 X sensitivity 50% (trail $DB < $DA)"
else
    bad "S-11 sens (trail $DA vs $DB)"
fi
setprefi sens_x 100
sleep 0.4

# ---- 4. export / profile ----
logcat -c
cfg --es op export
sleep 0.6
if log | grep -q 'export -> .*json' && log | grep -qE 'export -> .*[1-9][0-9]*B'; then
    ok "CF-03 config export"
else
    bad "CF-03 export ($(log | grep -c export))"
fi
logcat -c
cfg --es op save --es name testprofile
sleep 0.5
log | grep -q 'profile save testprofile' && ok "CF-05 profile save" || bad "CF-05 profile save"
logcat -c
cfg --es op load --es name testprofile
sleep 0.5
log | grep -q 'profile load testprofile ok=true' && ok "CF-05 profile load" || bad "CF-05 profile load"

wake
[ -n "$OLD_T" ] && settings put system screen_off_timeout "$OLD_T"
svc power stayon false >/dev/null 2>&1
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

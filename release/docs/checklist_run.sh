#!/system/bin/sh
# Automated part of docs/TEST-CHECKLIST.md. Run on the phone (adb shell sh ...).
# Prints PASS/FAIL per case and a summary; exits non-zero when anything fails.
PASS=0
FAIL=0
LG=/data/adb/gpm/helper.log

ok()  { echo "PASS  $*"; PASS=$((PASS + 1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL + 1)); }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; }
lcount() { wc -l < "$LG"; }
ltail() { tail -n "+$(( $1 + 1 ))" "$LG" 2>/dev/null; }
pos() { dumpsys input 2>/dev/null | grep -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)' | head -1; }
engine() { logcat -d -s DexPad DexPadLink 2>/dev/null; }

wake
svc power stayon true >/dev/null 2>&1
# never let the screen time out mid-run (battery power ignores stayon)
OLD_TIMEOUT=$(settings get system screen_off_timeout)
settings put system screen_off_timeout 600000

# ---------- precondition: never judge cases on a broken link ----------
if ! sh /data/local/tmp/dexpad_precondition.sh; then
    echo "ABORT: precondition not met, no test case was judged"
    svc power stayon false >/dev/null 2>&1
    exit 2
fi
ok "A0 link healthy (precondition)"
if [ -n "$(pidof gpminput)" ] && [ -S /data/user/0/com.dennis.dexpad/files/gpm.sock ]; then
    ok "A1 helper ready"
else
    bad "A1 helper ready"
fi

# ---------- A. connection ----------
if grep -q '^READY' /data/adb/gpm/helper.log && grep -q '^DEV ' /data/adb/gpm/helper.log; then
    ok "A2 helper ready + devices"
else
    bad "A2 helper ready + devices"
fi

# ---------- B. pointer ----------
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
P0=$(pos)
/data/local/tmp/vgpad stick 0 20000 700 3000 >/dev/null 2>&1
sleep 1
P1=$(pos)
if [ -n "$P1" ] && [ "$P1" != "$P0" ]; then ok "B1 left stick moves pointer"; else bad "B1 left stick moves pointer ($P0 -> $P1)"; fi

logcat -c
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'left button down'; then ok "B2 A = left click"; else bad "B2 A = left click"; fi

# ---------- C. d-pad ----------
logcat -c
L=$(lcount)
/data/local/tmp/vgpad hat 0 1 400 3000 >/dev/null 2>&1
sleep 1
NEW=$(ltail "$L")
if echo "$NEW" | grep -q 'PAD 108' && ! engine | grep -q 'arrow key'; then
    ok "C1 d-pad native forward"
else
    bad "C1 d-pad native forward"
fi
logcat -c
# make sure native arrow navigation is active first
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 0.5
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'A -> DPAD_CENTER (native nav)'; then ok "C2 A activates focus"; else bad "C2 A activates focus"; fi

logcat -c
/data/local/tmp/vgpad key 307 6000 2600 >/dev/null 2>&1 &
sleep 3.2
/data/local/tmp/vgpad hat 0 1 300 2600 >/dev/null 2>&1
sleep 1.2
if engine | grep -q 'mix .* x+down -> volume_down'; then ok "C3 combo X+down"; else bad "C3 combo X+down"; fi
wait

logcat -c
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 0.5
/data/local/tmp/vgpad stick 0 20000 500 3000 >/dev/null 2>&1
sleep 1
/data/local/tmp/vgpad key 304 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'native navigation OFF (stick moved)' && engine | grep -q 'left button down'; then
    ok "C4 stick exits native nav"
else
    bad "C4 stick exits native nav"
fi

# ---------- D. scroll ----------
L=$(lcount)
/data/local/tmp/vgpad stick 4 20000 800 3000 >/dev/null 2>&1
sleep 1
if ltail "$L" | grep -q 'SWIPE '; then ok "D1 right stick touch scroll"; else bad "D1 right stick touch scroll"; fi

# ---------- E. center ----------
L=$(lcount)
/data/local/tmp/vgpad key 317 300 800 >/dev/null 2>&1
sleep 1.3
C=$(grep 'CENTER' "$LG" 2>/dev/null | tail -1)
if echo "$C" | grep -q 'CENTER'; then ok "E1 L3 center ($C)"; else bad "E1 L3 center"; fi

# ---------- F. switch / close ----------
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
# make sure a second app exists so switch_app has a candidate
am start -n me.zhanghai.android.files/.filelist.FileListActivity >/dev/null 2>&1
sleep 2
logcat -c
L=$(lcount)
/data/local/tmp/vgpad key 315 200 3000 >/dev/null 2>&1
sleep 2
if ltail "$L" | grep -q 'SWITCH .* rc=0'; then ok "F1 START switch app"; else bad "F1 START switch app"; fi

am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 1
logcat -c
L=$(lcount)
/data/local/tmp/vgpad key 316 200 3000 >/dev/null 2>&1
sleep 3
if ltail "$L" | grep -q 'CLOSE_APP' && engine | grep -q 'alt+f4 -> close app on phone'; then
    ok "F2 GUIDE close app"
else
    bad "F2 GUIDE close app"
fi

# ---------- H. double press ----------
logcat -c
/data/local/tmp/vgpad double 307 60 90 3000 >/dev/null 2>&1
sleep 2
if engine | grep -q 'double x -> recents'; then ok "H1 double X = recents"; else bad "H1 double X = recents"; fi

# ---------- I. mode toggle ----------
logcat -c
/data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'mouse mode OFF'; then ok "I1 SHARE -> mouse off"; else bad "I1 SHARE -> mouse off"; fi
logcat -c
/data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
sleep 1
if engine | grep -q 'mouse mode ON'; then ok "I2 SHARE -> mouse on"; else bad "I2 SHARE -> mouse on"; fi

# ---------- C6. four directions ----------
sleep 0.5
L=$(lcount)
/data/local/tmp/vgpad hat 0 -1 300 3000 >/dev/null 2>&1
sleep 0.6
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 0.6
/data/local/tmp/vgpad hat -1 0 300 3000 >/dev/null 2>&1
sleep 0.6
/data/local/tmp/vgpad hat 1 0 300 3000 >/dev/null 2>&1
sleep 1
DIRS=$(ltail "$L" | grep -o 'PAD [0-9]*' | tr '\n' ' ')
if echo "$DIRS" | grep -q 'PAD 103' && echo "$DIRS" | grep -q 'PAD 108' && \
   echo "$DIRS" | grep -q 'PAD 105' && echo "$DIRS" | grep -q 'PAD 106'; then
    ok "C6 four d-pad directions ($DIRS)"
else
    bad "C6 four d-pad directions ($DIRS)"
fi

# ---------- I3. mouse mode off = native ----------
logcat -c
/data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
sleep 1
L=$(lcount)
logcat -c
/data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
sleep 1
if ! ltail "$L" | grep -q 'PAD ' && ! engine | grep -q 'arrow key'; then
    ok "I3 mode off -> system native"
else
    bad "I3 mode off -> system native"
fi
logcat -c
/data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
sleep 1

# ---------- J1. helper crash recovery ----------
HPID=$(pidof gpminput | awk '{print $1}')
if [ -n "$HPID" ]; then
    kill -9 "$HPID" 2>/dev/null
    sleep 20
    L=$(lcount)
    /data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
    sleep 1
    /data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
    sleep 1
    /data/local/tmp/vgpad hat 0 1 300 3000 >/dev/null 2>&1
    sleep 1
    if [ -n "$(pidof gpminput)" ] && ltail "$L" | grep -q 'PAD '; then
        ok "J1 helper crash recovery"
    else
        bad "J1 helper crash recovery"
    fi
else
    bad "J1 helper crash recovery (no pid)"
fi

# ---------- J2. engine crash recovery ----------
logcat -c
EPID=$(pidof com.dennis.dexpad | awk '{print $1}')
if [ -n "$EPID" ]; then
    kill -9 "$EPID" 2>/dev/null
    sleep 13
    if pidof com.dennis.dexpad >/dev/null 2>&1 && engine | grep -q 'helper ready'; then
        ok "J2 engine crash recovery"
    else
        bad "J2 engine crash recovery"
    fi
else
    bad "J2 engine crash recovery (no pid)"
fi
# ---------- K. centre accuracy (probe ground truth) ----------
am start -n com.dennis.dexpad/.PointerProbeActivity >/dev/null 2>&1
sleep 2
/data/local/tmp/vgpad stick 0 2000 300 1000 >/dev/null 2>&1
sleep 0.3
/data/local/tmp/vgpad key 317 150 2000 >/dev/null 2>&1
sleep 1
uiautomator dump /sdcard/k.xml >/dev/null 2>&1
KTEXT=$(grep -o 'text="x=[^"]*"' /sdcard/k.xml | head -1)
CX=$(echo "$KTEXT" | sed -n 's/.*x=\([0-9.]*\).*/\1/p' | cut -d. -f1)
CY=$(echo "$KTEXT" | sed -n 's/.*y=\([0-9.]*\).*/\1/p' | cut -d. -f1)
if [ -n "$CX" ] && [ -n "$CY" ] && [ "$CX" -ge 1260 ] && [ "$CX" -le 1300 ] && [ "$CY" -ge 780 ] && [ "$CY" -le 820 ]; then
    ok "K1 centre accuracy ($CX,$CY target 1280,800)"
else
    bad "K1 centre accuracy ($CX,$CY)"
fi

# ---------- M. vertical gestures ----------
input keyevent KEYCODE_HOME >/dev/null 2>&1
sleep 2
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 20000 700 2000 >/dev/null 2>&1
sleep 2
SW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep 'SWIPE ' | head -1)
SY1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
SY2=$(echo "$SW" | sed -n 's/.*-> [0-9]*,\([0-9]*\).*/\1/p')
if [ -n "$SY1" ] && [ "$SY1" -ge 800 ] && [ "$SY1" -le 1300 ] && [ "$SY2" -lt "$SY1" ]; then
    ok "M1 generic up swipe ($SW)"
else
    bad "M1 generic up swipe ($SW)"
fi

# a fullscreen launcher may swallow the shade gesture: test it in Settings
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
svc power stayon true >/dev/null 2>&1
am force-stop com.android.settings >/dev/null 2>&1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 3
WAKE2=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
TOP2=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
M0=$(wc -l < /data/adb/gpm/helper.log)
/data/local/tmp/vgpad stick 4 -20000 700 2000 >/dev/null 2>&1
sleep 2
screencap -p /sdcard/m3.png
M3=$(ls -l /sdcard/m3.png | awk '{print $5}')
SW=$(tail -n +$((M0+1)) /data/adb/gpm/helper.log 2>/dev/null | grep 'SWIPE ' | head -1)
SY1=$(echo "$SW" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
SY2=$(echo "$SW" | sed -n 's/.*-> [0-9]*,\([0-9]*\).*/\1/p')
SH=$(dumpsys window 2>/dev/null | grep -c NotificationShade)
if [ -n "$SY1" ] && [ "$SY1" -le 400 ] && [ "$SY2" -gt "$SY1" ] && { [ "$M3" -gt 1800000 ] || [ "$SH" -gt 12 ]; }; then
    ok "M2 notification shade ($SW, $M3, shade=$SH)"
else
    bad "M2 notification shade ($SW, $M3, shade=$SH, wake=$WAKE2 top=$TOP2)"
fi
input keyevent KEYCODE_BACK >/dev/null 2>&1

# ---------- N. forced landscape ----------
ROT=$(settings get system user_rotation)
IOR=$(wm get-ignore-orientation-request 2>/dev/null | grep -c true)
if [ "$ROT" = "1" ] && [ "$IOR" -ge 1 ]; then
    ok "N1 forced landscape (rot=$ROT ior=$IOR)"
else
    bad "N1 forced landscape (rot=$ROT ior=$IOR)"
fi
# keep the device usable after the test: mouse mode must end ON
if grep -q 'name="mode_on" value="false"' "$PREFXML" 2>/dev/null; then
    /data/local/tmp/vgpad key 167 150 3000 >/dev/null 2>&1
    sleep 1
fi
# ---------- P. power key (Y + L3) ----------
# "stay on while charging" would auto-wake the screen and hide the toggle
svc power stayon false >/dev/null 2>&1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
sleep 1
am start -n com.android.settings/.Settings >/dev/null 2>&1
sleep 2
W0=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
L=$(lcount)
/data/local/tmp/vgpad combo 308 317 600 3000 >/dev/null 2>&1
sleep 3
OFF=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
/data/local/tmp/vgpad combo 308 317 600 3000 >/dev/null 2>&1
sleep 3
ON=$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//')
POW=$(ltail "$L" | grep -c 'POWER')
if [ "$POW" -ge 2 ] && [ "$OFF" != "Awake" ] && [ "$ON" = "Awake" ]; then
    ok "P1 power key Y+L3 (off=$OFF on=$ON, POWER=$POW)"
else
    bad "P1 power key Y+L3 (off=$OFF on=$ON, POWER=$POW)"
fi

svc power stayon false >/dev/null 2>&1
[ -n "$OLD_TIMEOUT" ] && settings put system screen_off_timeout "$OLD_TIMEOUT"
echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1

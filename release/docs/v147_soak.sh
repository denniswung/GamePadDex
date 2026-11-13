#!/system/bin/sh
# v1.47 soak: 10 minutes of continuous input, memory/drift/latency sampling
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
OUT=/data/local/tmp/soak.log
: > $OUT
say() { echo "$*" | tee -a $OUT; }
log() { logcat -d -s DexPad 2>/dev/null; }
hy() { dumpsys input 2>/dev/null | grep -o 'at ([0-9.]*, [0-9.]*)' | head -1; }
pss() { dumpsys meminfo "$1" 2>/dev/null | sed -n 's/.*TOTAL PSS: *\([0-9]*\).*/\1/p' | head -1; }
drift() {
    $VG key 317 100 2500 >/dev/null 2>&1
    sleep 1.0
    hy | sed 's/at (//;s/)/ /' | awk '{print $1,$2}'
}

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
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
sleep 4
sh /data/local/tmp/dexpad_precondition.sh >/dev/null 2>&1 || say "PRECONDITION FAILED"

am start -n $PKG/.PointerProbeActivity >/dev/null 2>&1
sleep 2
logcat -c

APSS0=$(pss $PKG); HPSS0=$(pss gpminput)
say "start app_pss=${APSS0}KB helper_pss=${HPSS0}KB drift=$(drift)"

T0=$(date +%s)
MIN=0
while [ $MIN -lt 10 ]; do
    # ~60 s of mixed input: pointer, scroll, clicks, doubles, combos, dpad
    i=0
    while [ $i -lt 6 ]; do
        $VG stick 0 18000 700 2500 >/dev/null 2>&1
        $VG stick 1 -18000 700 0 >/dev/null 2>&1
        $VG stick 4 18000 600 0 >/dev/null 2>&1
        $VG key 304 100 0 >/dev/null 2>&1
        $VG double 307 60 110 0 >/dev/null 2>&1
        $VG combo 307 544 400 0 >/dev/null 2>&1
        $VG hat 1 200 0 >/dev/null 2>&1
        i=$((i+1))
    done
    MIN=$((MIN+1))
    APSS=$(pss $PKG); HPSS=$(pss gpminput)
    DR=$(drift)
    say "t=${MIN}min app_pss=${APSS}KB helper_pss=${HPSS}KB drift=${DR} alive=app:$(pidof $PKG | wc -w),helper:$(pidof gpminput | wc -w)"
done

T1=$(date +%s)
LAT=$(log | grep 'lat n=' | tail -3)
say "---- latency samples ----"
echo "$LAT" | tee -a $OUT

APSS1=$(pss $PKG); HPSS1=$(pss gpminput)
GROW=$(( (APSS1 - ${APSS0:-0}) ))
say "end app_pss=${APSS1}KB (grow ${GROW}KB) helper_pss=${HPSS1}KB elapsed=$((T1-T0))s"

CRASH=$(logcat -d 2>/dev/null | grep -cE 'FATAL EXCEPTION|ANR in com.dennis')
say "crashes/anr=$CRASH"

OK=1
[ -n "$(pidof $PKG)" ] || { say "FAIL app died"; OK=0; }
[ -n "$(pidof gpminput)" ] || { say "FAIL helper died"; OK=0; }
[ "$CRASH" -eq 0 ] || { say "FAIL crash/anr"; OK=0; }
[ "$GROW" -lt 40960 ] || { say "FAIL app pss grew ${GROW}KB"; OK=0; }
sh /data/local/tmp/dexpad_precondition.sh >/dev/null 2>&1 || { say "FAIL link unhealthy"; OK=0; }

settings put system screen_off_timeout "$OLD_T" 2>/dev/null
svc power stayon false >/dev/null 2>&1
if [ "$OK" = 1 ]; then say "SOAK RESULT: PASS"; else say "SOAK RESULT: FAIL"; exit 1; fi

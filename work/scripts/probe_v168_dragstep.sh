#!/system/bin/sh
# probe_v168_dragstep.sh -- 单次 move 1000px/500ms 的 getevent 分步证据（t30 验收2）
BIN=/data/adb/gpm/gpminput
LOG=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v168_step_out.txt
FIFO=/data/local/tmp/v168_step_in.fifo
RES=/data/local/tmp/v168_step.txt
GE=/data/local/tmp/v168_step_ge.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop $PKG >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
sleep 1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
logcat -c
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
log "top=$(dumpsys activity activities | grep -m1 topResumedActivity | tr -d '\r')"
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
send "q 2560 1600"; sleep 0.3
N=$(wc -l < "$LOG"); : > "$GE"
send "d 0 900 800"; sleep 0.4
dev=$(getevent -pl 2>/dev/null | awk '/add device/{d=$NF} /name:.*Gamepad Touch Panel/{print d; exit}')
log "touch_dev=$dev"
getevent -lt "$dev" > "$GE" 2>&1 &
GEPID=$!
sleep 0.2
send "m 0 1000 0 500"; sleep 0.9
send "e 0"; sleep 0.6
kill "$GEPID" 2>/dev/null
log "helper DRAG:"; tail -n +$((N+1)) "$LOG" | grep -a -E '^DRAG' | sed 's/^/  /' >> "$RES"
log "padtest:"; logcat -d -s PadProbe 2>/dev/null | grep -aE 'click-down|drag|swipe' | tail -4 | sed 's/^/  /' >> "$RES"
log "posY=$(grep -c 'ABS_MT_POSITION_Y' "$GE")"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

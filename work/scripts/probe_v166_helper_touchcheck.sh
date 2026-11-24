#!/system/bin/sh
# probe_v166_helper_touchcheck.sh -- 诊断虚拟触摸面板是否被 Android 当触摸屏、事件是否到应用
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v166_touchcheck_out.txt
FIFO=/data/local/tmp/v166_touchcheck_in.fifo
RES=/data/local/tmp/v166_touchcheck.txt
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
wm dismiss-keyguard >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
log "top=$(dumpsys activity activities | grep -m1 topResumedActivity | tr -d '\r')"
rm -f "$FIFO"; mkfifo "$FIFO"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
logcat -c
send "q 2560 1600"; sleep 0.3
send "k 1280 800 1"; sleep 0.3
send "k 1280 800 0"; sleep 0.6
log "helper OUT:"; cat "$OUT" | sed 's/^/  /' >> "$RES"
log "padtest logcat:"; logcat -d -s PadProbe 2>/dev/null | tail -8 | sed 's/^/  /' >> "$RES"
dumpsys input > /data/local/tmp/v166_touchcheck_din.txt 2>/dev/null
log "device section:"; grep -n -A16 'Gamepad Touch Panel' /data/local/tmp/v166_touchcheck_din.txt | head -40 | sed 's/^/  /' >> "$RES"
log "getevent -pl tail:"; getevent -pl 2>/dev/null | grep -B2 -A12 'Gamepad Touch Panel' | sed 's/^/  /' >> "$RES"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

#!/system/bin/sh
# probe_v169_ptr.sh -- v1.69 t41：验证助手 P（绝对定位）是否生效（绕过引擎/白名单）
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v169_ptr_out.txt
FIFO=/data/local/tmp/v169_ptr_in.fifo
RES=/data/local/tmp/v169_ptr.txt
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
for p in $(pgrep -f vgpad); do kill -9 "$p" 2>/dev/null; done
sleep 1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
log "ready=$(grep -ac '^READY' "$OUT") top=$(dumpsys activity activities | grep -m1 topResumedActivity | tr -d '\r')"
send "q 2560 1600"; sleep 0.3
log "-- c before:"; send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- P 400 1200 2560 1600 (visible pointer):"
send "P 400 1200 2560 1600"; sleep 1.5
grep -a -E 'POSPTR|POINTER' "$OUT" | tail -2 | sed 's/^/  /' >> "$RES"
send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- P 2000 300 2560 1600:"
send "P 2000 300 2560 1600"; sleep 1.5
send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- hide pointer (h), then P 1000 500:"
send "h"; sleep 0.8
send "P 1000 500 2560 1600"; sleep 1.8
grep -a -E 'POSPTR|POINTER' "$OUT" | tail -2 | sed 's/^/  /' >> "$RES"
send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
log "-- mouse wheel after P (H 3) + c:"
send "H 3"; sleep 0.8
send "c"; sleep 0.8; grep -a '^CURSOR ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

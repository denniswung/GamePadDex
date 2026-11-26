#!/system/bin/sh
# t47 收尾：? 自检 CAP 全 1 + 滚轮 9 步
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/t47_cap_out.txt
FIFO=/data/local/tmp/t47_cap_in.fifo
RES=/data/local/tmp/t47_cap.txt
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop $PKG >/dev/null 2>&1
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
sleep 1
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
send "?"; sleep 1.3
log "CAP lines:"; grep -a '^CAP ' "$OUT" | sed 's/^/  /' >> "$RES"
log "CAP all1=$(grep -a '^CAP ' "$OUT" | grep -vc ' 1$')/$(grep -ac '^CAP ' "$OUT") (0 = 全部为 1)"
log "ERR=$(grep -ac '^ERR' "$OUT")"
send "H 9"; sleep 0.6
log "wheel: $(grep -a '^WHEEL ' "$OUT" | tail -1)"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

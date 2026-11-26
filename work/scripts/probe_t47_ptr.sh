#!/system/bin/sh
# probe_t47_ptr.sh -- t47：P 五点精度 / 锚点 SWIPE / O 三档 / 隐藏恢复
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/t47_out.txt
FIFO=/data/local/tmp/t47_in.fifo
RES=/data/local/tmp/t47_ptr.txt
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
send "q 2560 1600"; sleep 0.3
log "ready=$(grep -ac '^READY' "$OUT")"

log "== P five points (closed loop) =="
for pt in "400 1200" "2000 300" "100 100" "2450 1500" "1280 800"; do
    X=${pt% *}; Y=${pt#* }
    send "P $X $Y 2560 1600"; sleep 1.3
    pos=$(grep -a '^POSPTR' "$OUT" | tail -1)
    send "c"; sleep 0.7
    cur=$(grep -a '^CURSOR ' "$OUT" | tail -1)
    log "  req=$X,$Y  $pos  =>  $cur"
done

log "== anchor: P then SWIPE start =="
send "P 1280 1000 2560 1600"; sleep 1.2
send "V 0 200 120 2560 1600"; sleep 1.0
grep -a '^SWIPE 0 ' "$OUT" | tail -1 | sed 's/^/  /' >> "$RES"

log "== O (L3 center) at pointer_speed 0/3/7 x3 =="
for ps in 0 3 7; do
    settings put system pointer_speed $ps; sleep 0.6
    for i in 1 2 3; do
        send "O 2560 1600 0 1"; sleep 1.3
        send "c"; sleep 0.7
        log "  ps=$ps #$i $(grep -a '^CURSOR ' "$OUT" | tail -1)"
    done
done
settings put system pointer_speed -1; sleep 0.6

log "== hide -> recreate -> P restore =="
send "P 900 600 2560 1600"; sleep 1.2
send "c"; sleep 0.6
log "  before hide: $(grep -a '^CURSOR ' "$OUT" | tail -1)"
send "h"; sleep 0.6
send "j"; sleep 0.6
send "P 900 600 2560 1600"; sleep 1.6
send "c"; sleep 0.7
log "  after restore: $(grep -a '^CURSOR ' "$OUT" | tail -1)"
log "  restore POSPTR: $(grep -a '^POSPTR' "$OUT" | tail -1)"

exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

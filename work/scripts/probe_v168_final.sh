#!/system/bin/sh
# probe_v168_final.sh -- t30 收尾：? 自检 ERR=0 + move 回包时延 + SWIPE_DROP 串行回归
BIN=/data/adb/gpm/gpminput
LOG=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v168_final_out.txt
FIFO=/data/local/tmp/v168_final_in.fifo
RES=/data/local/tmp/v168_final.txt
PAD=com.dennis.padtest
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
log "== final $(date) =="
log "ready=$(grep -ac '^READY' "$OUT")"
send "?"; sleep 1.2
log "selftest CAP lines=$(grep -ac '^CAP ' "$OUT") INFO lines=$(grep -ac '^INFO ' "$OUT") ERR=$(grep -ac '^ERR' "$OUT")"
grep -a -E '^(CAP|INFO|SELFTEST)' "$OUT" | head -14 | sed 's/^/  /' >> "$RES"

send "q 2560 1600"; sleep 0.3
send "d 0 1000 800"; sleep 0.4
for i in 1 2 3 4 5; do
    before=$(grep -ac '^DRAG move' "$OUT")
    t0=$(date +%s%N)
    send "m 0 20 0 40"
    n=0
    while [ $n -lt 100 ]; do
        now=$(grep -ac '^DRAG move' "$OUT")
        [ "$now" -gt "$before" ] && break
        sleep 0.005; n=$((n+1))
    done
    t1=$(date +%s%N)
    log "  move reply latency = $(( (t1 - t0) / 1000000 ))ms (poll 5ms, iter=$n)"
    sleep 0.15
done
send "e 0"; sleep 0.4
log "drag down/up lines:"
grep -a -E '^DRAG (down|up)' "$OUT" | tail -2 | sed 's/^/  /' >> "$RES"

# 串行队列回归：同 tick 双轴 -> 一条注入 + SWIPE_DROP
N=$(wc -l < "$LOG")
send "V 0 600 2560 1600"; sleep 0.1
send "Z 0 -600 200 2560 1600 30 1280 480"; sleep 0.1
send "V 0 600 2560 1600"; sleep 0.1
sleep 1.1
log "  queue lines:"
tail -n +$((N+1)) "$LOG" | grep -a -E 'SWIPE(_DROP)? ' | sed 's/^/    /' >> "$RES"
log "  OUT ERR count=$(grep -ac '^ERR' "$OUT")"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

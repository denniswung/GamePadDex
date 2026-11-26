#!/system/bin/sh
# probe_sock_verify3.sh -- 修正测量：SCR-016 增量判定 / SCR-020 列表首项推断 offset
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/sv3_out.txt
FIFO=/data/local/tmp/sv3_in.fifo
RES=/data/local/tmp/sv3.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
hcmd() { echo "$*" >&3; }
dump() { uiautomator dump /sdcard/sv3_$1.xml >/dev/null 2>&1; }
firstitem() { grep -a -o '列表项 #[0-9]*' /sdcard/sv3_$1.xml | head -1; }
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
log "== sv3 $(date) ready=$(grep -ac '^READY' "$OUT") =="
hcmd "q 2560 1600"; sleep 0.3

# SCR-016：隐藏指针 -> 滚轮；用增量计数 + 记录 MOUSE_REOPEN
W0=$(grep -ac '^WHEEL 3' "$OUT")
hcmd "h"; sleep 0.5
T0=$(date +%s%N)
hcmd "H 3"
i=0; while [ $i -lt 200 ]; do
    W1=$(grep -ac '^WHEEL 3' "$OUT")
    [ "$W1" -gt "$W0" ] && break
    sleep 0.01; i=$((i+1))
done
T1=$(date +%s%N)
log "SCR-016 h->WHEEL latency=$(( (T1-T0)/1000000 ))ms (轮询 10ms) wheel_before=$W0 after=$W1"
grep -a -E 'POINTER off|MOUSE_REOPEN|WHEEL 3' "$OUT" | tail -3 | sed 's/^/  /' >> "$RES"

# SCR-020：列表内连续 5 次上滑，读首项推 offset
hcmd "j"; sleep 0.6
hcmd "P 1280 1000 2560 1600"; sleep 1.3
dump b0
log "SCR-020 before: $(firstitem b0)"
for i in 1 2 3 4 5; do
    hcmd "Z 0 -600 200 2560 1600"; sleep 1.0
    dump s$i
    log "  swipe#$i first_item=$(firstitem s$i) swipe=$(grep -a '^SWIPE 0 ' "$OUT" | tail -1)"
done
log "  last SWIPE: $(grep -a '^SWIPE 0 ' "$OUT" | tail -1)"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

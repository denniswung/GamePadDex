#!/system/bin/sh
# probe_sock_verify2.sh -- 直连助手（绕过引擎）在 release 字节上复核 BLOCKED
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/sv2_out.txt
FIFO=/data/local/tmp/sv2_in.fifo
RES=/data/local/tmp/sv2.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
hcmd() { echo "$*" >&3; }
dump() { uiautomator dump /sdcard/sv2_$1.xml >/dev/null 2>&1; }
txt() { grep -a -o "$1" /sdcard/sv2_$2.xml | head -1; }
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
log "== sv2 $(date) helper=$HPID ready=$(grep -ac '^READY' "$OUT") =="
hcmd "q 2560 1600"; sleep 0.3

# SCR-017 不可滚区域滚轮
dump a
log "SCR-017 before: $(txt '纵向 offset=[0-9]*' a) | $(txt '固定区域[^<]*' a) | $(txt '后端统计[^<]*' a)"
hcmd "P 1280 250 2560 1600"; sleep 1.3
hcmd "c"; sleep 0.8
log "  pointer: $(grep -a '^CURSOR ' "$OUT" | tail -1)"
hcmd "H 3"; sleep 0.5; hcmd "H 3"; sleep 0.5; hcmd "H 3"; sleep 1.2
dump b
log "SCR-017 after:  $(txt '纵向 offset=[0-9]*' b) | $(txt '固定区域[^<]*' b) | $(txt '后端统计[^<]*' b)"
log "  WHEEL: $(grep -a '^WHEEL ' "$OUT" | tail -3 | tr '\n' ' ')"

# SCR-016 隐藏指针后滚轮
hcmd "h"; sleep 0.4
T0=$(date +%s%N)
hcmd "H 3"
i=0; while [ $i -lt 100 ]; do grep -aq '^WHEEL 3' "$OUT" && break; sleep 0.02; i=$((i+1)); done
T1=$(date +%s%N)
log "SCR-016 hide->WHEEL latency=$(( (T1-T0)/1000000 ))ms (轮询 20ms)；log:"
grep -a -E 'POINTER|MOUSE_REOPEN|WHEEL 3' "$OUT" | tail -3 | sed 's/^/  /' >> "$RES"

# SCR-020 / MIX-028 边界续拖（列表内重复滑动直到边界）
hcmd "j"; sleep 0.5
hcmd "P 1280 1000 2560 1600"; sleep 1.3
log "SCR-020 before: $(txt '纵向 offset=[0-9]*' a)"
for i in 1 2 3 4; do
    hcmd "Z 0 -600 200 2560 1600"; sleep 1.0
    dump z$i
    log "  swipe#$i: $(txt '纵向 offset=[0-9]*' z$i)  $(grep -a '^SWIPE 0 ' "$OUT" | tail -1)"
done

# E2E-010 拖拽中熄屏
hcmd "d 0 1280 900"; sleep 0.3
hcmd "m 0 0 -150 300"; sleep 0.3
log "E2E-010 drag active: $(grep -a '^DRAG move' "$OUT" | tail -1)"
hcmd "p"; sleep 3.0
log "  after power off:"
grep -a -E '^DRAG (down|up)' "$OUT" | tail -2 | sed 's/^/    /' >> "$RES"
hcmd "p"; sleep 2.0
hcmd "k 1000 900 1"; sleep 0.1; hcmd "k 1000 900 0"; sleep 0.5
log "  after wake tap: $(grep -a '^TOUCH ' "$OUT" | tail -2 | tr '\n' ' ')"
log "  ERR=$(grep -ac '^ERR' "$OUT")"
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

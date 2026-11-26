#!/system/bin/sh
# probe_sock_verify.sh -- release 字节上的 BLOCKED 复核：SCR-017 / SCR-016 / SCR-020 / MIX-028 / E2E-010
RES=/data/local/tmp/sock_verify.txt
LOG=/data/adb/gpm/helper.log
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
hcmd() { am broadcast -a com.dennis.dexpad.HCMD -n com.dennis.dexpad/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
dump() { uiautomator dump /sdcard/sv_$1.xml >/dev/null 2>&1; }
txt() { grep -a -o "$1" /sdcard/sv_$2.xml | head -1; }
: > "$RES"
log "== sock verify $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3

# ---------- SCR-017：不可滚区域滚轮 ----------
dump a
log "SCR-017 before: $(txt '纵向 offset=[0-9]*' a) | $(txt '固定区域[^<]*' a) | $(txt '后端统计[^<]*' a)"
hcmd "P 1280 250 2560 1600"; sleep 1.3
hcmd "c"; sleep 0.8
log "  pointer: $(grep -a '^CURSOR ' "$LOG" | tail -1)"
hcmd "H 3"; sleep 0.5; hcmd "H 3"; sleep 0.5; hcmd "H 3"; sleep 1.2
dump b
log "SCR-017 after:  $(txt '纵向 offset=[0-9]*' b) | $(txt '固定区域[^<]*' b) | $(txt '后端统计[^<]*' b)"
log "  WHEEL lines: $(grep -a '^WHEEL ' "$LOG" | tail -3 | tr '\n' ' ')"

# ---------- SCR-016：隐藏指针后滚轮 ----------
hcmd "h"; sleep 0.3
T0=$(date +%s%N)
hcmd "H 3"; sleep 1.0
T1=$(date +%s%N)
log "SCR-016 hide->wheel: elapsed=$(( (T1-T0)/1000000 ))ms (含广播)；helper log:"
tail -6 "$LOG" | sed 's/^/  /' >> "$RES"
log "  WHEEL count after hide: $(grep -ac '^WHEEL 3' "$LOG")"

# ---------- SCR-020 / MIX-028：边界续拖 ----------
hcmd "j"; sleep 0.6
hcmd "P 1280 1000 2560 1600"; sleep 1.3
log "SCR-020 before: $(txt '纵向 offset=[0-9]*' a)"
for i in 1 2 3 4; do
    hcmd "Z 0 600 200 2560 1600"; sleep 1.0
    dump z$i
    log "  swipe#$i: $(txt '纵向 offset=[0-9]*' z$i)"
done
log "  last SWIPE: $(grep -a '^SWIPE 0 ' "$LOG" | tail -1)"
log "  drag re-anchor (engine): $(logcat -d -s DexPad 2>/dev/null | grep -a 'drag re-anchor' | tail -2 | tr '\n' ' ')"

# ---------- E2E-010：按住 RB（drag）时熄屏 ----------
hcmd "d 0 1280 900"; sleep 0.3
hcmd "m 0 0 -150 300"; sleep 0.3
log "E2E-010 drag active: $(grep -a '^DRAG move' "$LOG" | tail -1)"
hcmd "p"; sleep 3.0
log "  after screen off, DRAG lines:"
grep -a -E '^DRAG (down|up)' "$LOG" | tail -2 | sed 's/^/    /' >> "$RES"
hcmd "p"; sleep 2.0
hcmd "k 1000 900 1"; sleep 0.1; hcmd "k 1000 900 0"; sleep 0.5
log "  after wake tap: $(grep -a '^TOUCH ' "$LOG" | tail -2 | tr '\n' ' ')"
log DONE

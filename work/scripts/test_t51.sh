#!/system/bin/sh
# test_t51.sh -- detached drag via root control channel + frames/offset + concurrent app channel
RES=/data/local/tmp/t51.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
LOG=/data/adb/gpm/helper.log
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
log() { echo "$@" | tee -a "$RES"; }
ctl() { timeout 6 "$G" "$S" "$@" 2>&1 | sed 's/^/  /' >> "$RES"; }
dump() { uiautomator dump /sdcard/t51_$1.xml >/dev/null 2>&1; }
firstitem() { grep -a -o '列表项 #[0-9]*' /sdcard/t51_$1.xml | head -1; }
offset() { grep -a -o '纵向 offset=[0-9]*' /sdcard/t51_$1.xml | head -1; }
: > "$RES"
log "== t51 $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
log "socket: $(ls -l $S 2>&1)"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3

log "-- A) detached drag (每条命令一个连接), engine running"
dump a
log "before: $(offset a) $(firstitem a)"
ctl d 0 1280 1000
ctl m 0 0 -400 300
sleep 0.6
ctl e 0
sleep 1.0
dump b
log "after:  $(offset b) $(firstitem b)"
grep -a -E '^DRAG (down|move|up)' "$LOG" | tail -3 | sed 's/^/  /' >> "$RES"

log "-- B) burst on one connection (d/m/e 同一连接)"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
dump c
log "before: $(offset c)"
timeout 6 "$G" "$S" d 0 1280 1000 m 0 0 -400 300 e 0 2>&1 | sed 's/^/  /' >> "$RES"
sleep 1.0
dump d
log "after:  $(offset d) $(firstitem d)"
grep -a -E '^DRAG (down|move|up)' "$LOG" | tail -3 | sed 's/^/  /' >> "$RES"

log "-- C) engine stopped: detached drag still emits frames"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop $PKG >/dev/null 2>&1
sleep 1
log "  engine=$(pidof com.dennis.dexpad) helper=$(pidof gpminput)"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
dump e
log "before: $(offset e)"
ctl d 0 1280 1000
ctl m 0 0 -400 300
sleep 0.6
ctl e 0
sleep 1.0
dump f
log "after:  $(offset f) $(firstitem f)"
grep -a -E '^DRAG (down|move|up)' "$LOG" | tail -3 | sed 's/^/  /' >> "$RES"

log "-- D) restore engine"
setsid /system/bin/sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 2
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

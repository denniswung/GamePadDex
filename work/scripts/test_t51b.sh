#!/system/bin/sh
RES=/data/local/tmp/t51b.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
LOG=/data/adb/gpm/helper.log
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
dump() { uiautomator dump /sdcard/t51b_$1.xml >/dev/null 2>&1; }
firstitem() { grep -a -o '列表项 #[0-9]*' /sdcard/t51b_$1.xml | head -1; }
: > "$RES"
log "== t51b $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3

log "-- A) burst one connection: d/m/e"
N=$(wc -l < "$LOG")
printf 'd 0 1280 1000\nm 0 0 -450 300\ne 0\n' | timeout 6 "$G" "$S" - 2>&1 | head -6 | sed 's/^/  out: /' >> "$RES"
sleep 1.2
dump a
log "  DRAG: $(tail -n +$((N+1)) "$LOG" | grep -a -E '^DRAG' | tr '\n' ' ')"
log "  padtest: $(firstitem a)"

log "-- B) detached (3 connections): d | m | (sleep) | e"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
N=$(wc -l < "$LOG")
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
timeout 5 "$G" "$S" m 0 0 -450 300 >/dev/null 2>&1
sleep 0.7
log "  app channel during drag: $(tail -n +$((N+1)) "$LOG" | grep -a -c PING) PING"
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 1.2
dump b
log "  DRAG: $(tail -n +$((N+1)) "$LOG" | grep -a -E '^DRAG' | tr '\n' ' ')"
log "  padtest: $(firstitem b)"
log DONE

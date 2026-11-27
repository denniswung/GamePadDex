#!/system/bin/sh
RES=/data/local/tmp/t66b.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
APP=/data/data/com.dennis.dexpad/files/gpm.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t66b.xml >/dev/null 2>&1; }
off() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t66b.xml | head -1); echo "${g:-offset=?}"; }
: > "$RES"
log "== $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
log "sock: $(ls -l $CTL 2>&1)"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
ui; log "init: $(off)"

log "-- control channel (capture replies) --"
log "  d: $(timeout 5 "$G" "$CTL" d 0 1280 1000 2>&1 | tr '\n' ' ')"
sleep 0.1
log "  m: $(timeout 5 "$G" "$CTL" m 0 0 -400 300 2>&1 | tr '\n' ' ')"
sleep 0.8
log "  e: $(timeout 5 "$G" "$CTL" e 0 2>&1 | tr '\n' ' ')"
sleep 1.0
ui; log "  after: $(off)"
log "  DRAG: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"
log "  any DRAG: $(grep -a -c '^DRAG ' /data/adb/gpm/helper.log)"

log "-- app channel direct (engine stopped) --"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop com.dennis.dexpad >/dev/null 2>&1
sleep 1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
ui; log "  before: $(off)"
log "  helper=$(pidof gpminput)"
log "  d: $(timeout 5 "$G" "$APP" d 0 1280 1000 2>&1 | tr '\n' ' ')"
sleep 0.1
log "  m: $(timeout 5 "$G" "$APP" m 0 0 -400 300 2>&1 | tr '\n' ' ')"
sleep 0.8
log "  e: $(timeout 5 "$G" "$APP" e 0 2>&1 | tr '\n' ' ')"
sleep 1.0
ui; log "  after: $(off)"
log "  DRAG: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"
log DONE

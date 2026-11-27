#!/system/bin/sh
RES=/data/local/tmp/t66e.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t66e.xml >/dev/null 2>&1; }
off() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t66e.xml | head -1); echo "${g:-offset=?}"; }
: > "$RES"
P0=$(pidof gpminput)
log "== t66e helper=$P0 =="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
ui; log "init: $(off)"
log "ARG: $(timeout 5 "$G" "$CTL" d foo 2>&1 | tr '\n' ' ')"
log "STATE m: $(timeout 5 "$G" "$CTL" m 0 0 -10 100 2>&1 | tr '\n' ' ')"
log "STATE e: $(timeout 5 "$G" "$CTL" e 0 2>&1 | tr '\n' ' ')"
log "d: $(timeout 5 "$G" "$CTL" d 0 1280 1000 2>&1 | tr '\n' ' ')"
sleep 0.2
log "m: $(timeout 5 "$G" "$CTL" m 0 0 -400 300 2>&1 | tr '\n' ' ')"
sleep 1.0
log "e: $(timeout 5 "$G" "$CTL" e 0 2>&1 | tr '\n' ' ')"
sleep 1.2
ui; log "after: $(off)"
log "DRAG: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"
log "pid: $P0 -> $(pidof gpminput)"

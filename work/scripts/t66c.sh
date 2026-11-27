#!/system/bin/sh
RES=/data/local/tmp/t66c.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
log "helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad)"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
N=$(wc -l < /data/adb/gpm/helper.log)
log "d out: [$(timeout 5 "$G" "$CTL" d 0 1280 1000 2>&1 | tr '\n' ' ')]"
sleep 0.6
log "after d lines:"; tail -n +$((N+1)) /data/adb/gpm/helper.log | sed 's/^/  /' >> "$RES"
N2=$(wc -l < /data/adb/gpm/helper.log)
log "m out: [$(timeout 5 "$G" "$CTL" m 0 0 -400 300 2>&1 | tr '\n' ' ')]"
sleep 1.0
log "after m lines:"; tail -n +$((N2+1)) /data/adb/gpm/helper.log | sed 's/^/  /' >> "$RES"
log "e out: [$(timeout 5 "$G" "$CTL" e 0 2>&1 | tr '\n' ' ')]"
sleep 0.6
log "last 5:"; tail -5 /data/adb/gpm/helper.log | sed 's/^/  /' >> "$RES"

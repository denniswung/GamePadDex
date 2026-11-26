#!/system/bin/sh
RES=/data/local/tmp/t59c.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
log "== tap raw capture =="
getevent -l /dev/input/event22 > /data/local/tmp/t59k.txt 2>&1 &
GE=$!
sleep 0.5
timeout 5 "$G" "$S" k 1280 802 1 >/dev/null 2>&1
sleep 0.2
timeout 5 "$G" "$S" k 1280 802 0 >/dev/null 2>&1
sleep 0.3
timeout 5 "$G" "$S" k 200 200 1 >/dev/null 2>&1
sleep 0.2
timeout 5 "$G" "$S" k 200 200 0 >/dev/null 2>&1
sleep 0.5
kill $GE 2>/dev/null
log "raw events:"; head -14 /data/local/tmp/t59k.txt | sed 's/^/  /' >> "$RES"
log "helper TOUCH: $(grep -a '^TOUCH ' /data/adb/gpm/helper.log | tail -4 | tr '\n' ' ')"

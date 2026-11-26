#!/system/bin/sh
RES=/data/local/tmp/t59d.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
log "== P six points (current bytes) =="
timeout 5 "$G" "$S" j >/dev/null 2>&1
sleep 0.5
for pt in "700 1000" "100 100" "2450 1500" "2000 300" "1280 802" "1280 800"; do
    X=${pt% *}; Y=${pt#* }
    timeout 5 "$G" "$S" P $X $Y 2560 1600 >/dev/null 2>&1
    sleep 1.2
    C=$(timeout 5 "$G" "$S" c 2>&1 | grep -a '^CURSOR ' | tail -1)
    P2=$(grep -a '^POSPTR' /data/adb/gpm/helper.log | tail -2 | head -1)
    log "req=$X,$Y  $P2  => $C"
done

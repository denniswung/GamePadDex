#!/system/bin/sh
RES=/data/local/tmp/t61s.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t61s.xml >/dev/null 2>&1; }
gy() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t61s.xml | head -1); echo "${g:-offset=?}"; }
: > "$RES"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
timeout 5 "$G" "$S" j >/dev/null 2>&1
sleep 0.5
timeout 5 "$G" "$S" P 1280 900 2560 1600 >/dev/null 2>&1
sleep 1.0
timeout 5 "$G" "$S" c > /data/local/tmp/t61sc.txt 2>&1
log "c: $(grep -a '^CURSOR ' /data/local/tmp/t61sc.txt | tail -1)"
ui; log "before: $(gy)"
N=$(wc -l < /data/adb/gpm/helper.log)
timeout 5 "$G" "$S" S 8 >/dev/null 2>&1
sleep 1.0
ui; log "after S 8: $(gy)"
log "WHEEL lines: $(tail -n +$((N+1)) /data/adb/gpm/helper.log | grep -a WHEEL | tr '\n' ' ')"

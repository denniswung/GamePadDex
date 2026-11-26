#!/system/bin/sh
RES=/data/local/tmp/t61.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t61u.xml >/dev/null 2>&1; }
gx() { g=$(grep -a -o '横向 scrollX=[0-9]*' /sdcard/t61u.xml | head -1); echo "${g:-scrollX=?}"; }
gy() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t61u.xml | head -1); echo "${g:-offset=?}"; }
: > "$RES"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
ui; log "init: $(gx) | $(gy)"

log "== A3) P(1280,1507)+right stick horizontal =="
timeout 5 "$G" "$S" P 1280 1507 2560 1600 >/dev/null 2>&1
sleep 1.2
timeout 5 "$G" "$S" c > /data/local/tmp/t61c.txt 2>&1
log "  c: $(grep -a '^CURSOR ' /data/local/tmp/t61c.txt | tail -1)"
timeout 5 "$G" "$S" H 8 >/dev/null 2>&1
sleep 1.0
ui; log "  after H 8 (control): $(gx)"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
timeout 5 "$G" "$S" P 1280 1507 2560 1600 >/dev/null 2>&1
sleep 1.0
/data/local/tmp/vgpad stick 3 30000 900 >/dev/null 2>&1
sleep 1.5
ui; log "  after stick (vgpad): $(gx)"

log "== C) vertical wheel S 8 =="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
ui; log "  before: $(gy)"
timeout 5 "$G" "$S" S 8 >/dev/null 2>&1
sleep 1.0
ui; log "  after S 8: $(gy)"
log "  helper: $(grep -a '^WHEEL -8 h=0\|^WHEEL 8 h=0' /data/adb/gpm/helper.log | tail -1)"

log "== B) d/m/e detached =="
P0=$(pidof gpminput)
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
ui; log "  before: $(gy)"
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
sleep 0.1
timeout 5 "$G" "$S" m 0 0 -400 300 >/dev/null 2>&1
sleep 0.8
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 1.0
ui; log "  after: $(gy)"
log "  d/m/e: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"
log "  pid: $P0 -> $(pidof gpminput)"
log DONE

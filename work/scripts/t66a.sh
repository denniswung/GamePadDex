#!/system/bin/sh
RES=/data/local/tmp/t66a.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
APP=/data/data/com.dennis.dexpad/files/gpm.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t66.xml >/dev/null 2>&1; }
off() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t66.xml | head -1); echo "${g:-offset=?}"; }
stat() { g=$(grep -a -o '后端统计[^<]*' /sdcard/t66.xml | head -1); echo "${g:-stat=?}"; }
: > "$RES"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
ui; log "init: $(off) | $(stat)"

log "== S0) real input swipe sanity =="
input swipe 1280 1000 1280 500 300
sleep 1.2
ui; log "  after swipe: $(off) | $(stat)"

log "== A) control channel d/m/e =="
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
ui; log "  before: $(off)"
timeout 5 "$G" "$CTL" d 0 1280 1000 >/dev/null 2>&1
sleep 0.1
timeout 5 "$G" "$CTL" m 0 0 -400 300 >/dev/null 2>&1
sleep 0.8
timeout 5 "$G" "$CTL" e 0 >/dev/null 2>&1
sleep 1.0
ui; log "  after: $(off) | $(stat)"
log "  helper: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"
log DONE

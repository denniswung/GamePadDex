#!/system/bin/sh
RES=/data/local/tmp/t71b.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t71b.xml >/dev/null 2>&1; }
stat() { g=$(grep -a -o '后端统计[^<]*' /sdcard/t71b.xml | head -1); echo "${g:-stat=?}"; }
off() { g=$(grep -a -o '纵向 offset=[0-9]*' /sdcard/t71b.xml | head -1); echo "${g:-offset=?}"; }
: > "$RES"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
timeout 5 "$G" "$CTL" j >/dev/null 2>&1
sleep 0.4
timeout 5 "$G" "$CTL" P 1280 900 2560 1600 >/dev/null 2>&1
sleep 0.8
ui; log "before: $(off) | $(stat)"
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.0
ui; log "after S8: $(off) | $(stat)"
timeout 5 "$G" "$CTL" H 8 >/dev/null 2>&1
sleep 1.0
ui; log "after H8: $(grep -a -o '横向 scrollX=[0-9]*' /sdcard/t71b.xml | head -1) | $(stat)"

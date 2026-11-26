#!/system/bin/sh
RES=/data/local/tmp/t61k.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t61k.xml >/dev/null 2>&1; }
stat() { grep -a -o '后端统计[^<]*' /sdcard/t61k.xml | head -1; }
fix() { grep -a -o '固定区域[^<]*' /sdcard/t61k.xml | head -1; }
: > "$RES"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
ui; log "before: $(stat) | $(fix)"
timeout 5 "$G" "$S" k 1280 1000 1 >/dev/null 2>&1
sleep 0.15
timeout 5 "$G" "$S" k 1280 1000 0 >/dev/null 2>&1
sleep 0.8
ui; log "after k: $(stat) | $(fix)"
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
sleep 0.1
timeout 5 "$G" "$S" m 0 0 -300 240 >/dev/null 2>&1
sleep 0.6
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 0.8
ui; log "after drag: $(stat) | $(fix)"
log "helper: $(grep -a -E '^TOUCH down|^DRAG up' /data/adb/gpm/helper.log | tail -3 | tr '\n' ' ')"

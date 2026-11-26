#!/system/bin/sh
RES=/data/local/tmp/t54c.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
LOG=/data/adb/gpm/helper.log
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
uiautomator dump /sdcard/t54c_a.xml >/dev/null 2>&1
log "before: $(grep -a -o '列表项 #[0-9]*' /sdcard/t54c_a.xml | head -1) $(grep -a -o '纵向 offset=[0-9]*' /sdcard/t54c_a.xml | head -1)"
timeout 5 "$G" "$S" d 0 1280 1000 >/dev/null 2>&1
sleep 0.2
timeout 5 "$G" "$S" m 0 0 -400 300 >/dev/null 2>&1
sleep 1.0
timeout 5 "$G" "$S" e 0 >/dev/null 2>&1
sleep 1.0
uiautomator dump /sdcard/t54c_b.xml >/dev/null 2>&1
log "after:  $(grep -a -o '列表项 #[0-9]*' /sdcard/t54c_b.xml | head -1) $(grep -a -o '纵向 offset=[0-9]*' /sdcard/t54c_b.xml | head -1)"
log "DRAG: $(grep -a -E '^DRAG (down|up)' "$LOG" | tail -2 | tr '\n' ' ')"

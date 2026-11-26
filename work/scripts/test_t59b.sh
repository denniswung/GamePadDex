#!/system/bin/sh
RES=/data/local/tmp/t59b.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
page() { uiautomator dump /sdcard/t59p.xml >/dev/null 2>&1; grep -a -o '第 [0-9]* 页' /sdcard/t59p.xml | head -3 | tr '\n' ' '; }
: > "$RES"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
log "A) real input swipe at y=802: before=[$(page)]"
input swipe 1280 802 1582 802 120
sleep 1.2
log "   after=[$(page)]"
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
log "B) helper P(1280,802)+V swipe: before=[$(page)]"
timeout 5 "$G" "$S" P 1280 802 2560 1600 >/dev/null 2>&1
sleep 0.8
timeout 5 "$G" "$S" V 0 300 120 2560 1600 >/dev/null 2>&1
sleep 1.2
log "   after=[$(page)]"
log "helper: $(grep -a -E 'SWIPE 0|POSPTR' /data/adb/gpm/helper.log | tail -2 | tr '\n' ' ')"

#!/system/bin/sh
RES=/data/local/tmp/t59a.txt
G=/data/local/tmp/gpmctl
S=/data/adb/gpm/gpmctl.sock
PAD=com.dennis.padtest
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
uiautomator dump /sdcard/t59_a.xml >/dev/null 2>&1
log "before page: $(grep -a -o '第 [0-9]* 页' /sdcard/t59_a.xml | head -3 | tr '\n' ' ')"
# 记录注入的 raw ABS
getevent -l /dev/input/event22 > /data/local/tmp/t59_ev.txt 2>&1 &
GE=$!
sleep 0.5
timeout 5 "$G" "$S" P 1280 802 2560 1600
sleep 1.0
timeout 5 "$G" "$S" c
timeout 5 "$G" "$S" V 0 300 120 2560 1600
sleep 1.2
kill $GE 2>/dev/null
uiautomator dump /sdcard/t59_b.xml >/dev/null 2>&1
log "after page:  $(grep -a -o '第 [0-9]* 页' /sdcard/t59_b.xml | head -3 | tr '\n' ' ')"
log "event (head):"
head -12 /data/local/tmp/t59_ev.txt | sed 's/^/  /' >> "$RES"
log "helper: $(grep -a -E 'POSPTR|SWIPE 0|CURSOR ' /data/adb/gpm/helper.log | tail -4 | tr '\n' ' ')"

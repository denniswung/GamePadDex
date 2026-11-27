#!/system/bin/sh
RES=/data/local/tmp/t71a.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t71.xml >/dev/null 2>&1; }
sig() { grep -a -o 'text="[^"]*"' /sdcard/t71.xml | sed -n '1,12p' | tr '\n' '|'; }
: > "$RES"
log "== t71 $(date) helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad) =="
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
ui; log "before: $(sig)"
getevent -lt /dev/input/event19 > /data/local/tmp/t71_ev.txt 2>&1 &
GE=$!
sleep 0.5
timeout 5 "$G" "$CTL" P 1280 800 2560 1600 >/dev/null 2>&1
sleep 1.0
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.0
kill $GE 2>/dev/null
ui; log "after:  $(sig)"
log "wheel events: $(grep -a -c WHEEL /data/local/tmp/t71_ev.txt)"
grep -a -E 'WHEEL' /data/local/tmp/t71_ev.txt | head -4 | sed 's/^/  /' >> "$RES"
log "dumpsys: $(dumpsys input 2>/dev/null | grep -a -A6 'Gamepad Mouse Pointer' | grep -a -E 'Classes|Sources|Rel|Key|Propert|Descriptor' | tr '\n' ' ')"

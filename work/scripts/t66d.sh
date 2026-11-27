#!/system/bin/sh
RES=/data/local/tmp/t66d.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
log() { echo "$@" | tee -a "$RES"; }
ui() { uiautomator dump /sdcard/t66d.xml >/dev/null 2>&1; }
first() { grep -a -o 'text="[^"]*"' /sdcard/t66d.xml | sed -n '3,8p' | tr '\n' ' '; }
: > "$RES"
log "helper=$(pidof gpminput) engine=$(pidof com.dennis.dexpad)"
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
ui; log "before: $(first)"
timeout 5 "$G" "$CTL" d 0 1280 1000 >/dev/null 2>&1
sleep 0.2
timeout 5 "$G" "$CTL" m 0 0 -500 400 >/dev/null 2>&1
sleep 1.2
timeout 5 "$G" "$CTL" e 0 >/dev/null 2>&1
sleep 1.0
ui; log "after:  $(first)"
log "DRAG: $(grep -a '^DRAG up' /data/adb/gpm/helper.log | tail -1)"

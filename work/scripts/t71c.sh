#!/system/bin/sh
RES=/data/local/tmp/t71c.txt
G=/data/local/tmp/gpmctl
CTL=/data/adb/gpm/gpmctl.sock
log() { echo "$@" | tee -a "$RES"; }
shot() { screencap -p /sdcard/t71_$1.png; }
: > "$RES"
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3
timeout 5 "$G" "$CTL" j >/dev/null 2>&1
sleep 0.4
timeout 5 "$G" "$CTL" P 1280 800 2560 1600 >/dev/null 2>&1
sleep 1.0
shot a
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.2
shot b
timeout 5 "$G" "$CTL" S 8 >/dev/null 2>&1
sleep 1.2
shot c
input swipe 1280 900 1280 400 300
sleep 1.2
shot d
log "shots done: a b c d"

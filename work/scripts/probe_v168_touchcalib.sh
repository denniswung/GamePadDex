#!/system/bin/sh
# probe_v168_touchcalib.sh -- 标定虚拟触摸面板：请求 (x,y) -> padtest 收到的逻辑坐标
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v168_calib_out.txt
FIFO=/data/local/tmp/v168_calib_in.fifo
RES=/data/local/tmp/v168_calib.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
: > "$RES"
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
am force-stop $PKG >/dev/null 2>&1
am force-stop $PAD >/dev/null 2>&1
for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
sleep 1
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
log "top=$(dumpsys activity activities | grep -m1 topResumedActivity | tr -d '\r')"
rm -f "$FIFO"; mkfifo "$FIFO"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
send "q 2560 1600"; sleep 0.3
logcat -c
for pt in "400 300" "2000 1400" "1280 800" "200 1200" "2200 400"; do
    X=${pt% *}; Y=${pt#* }
    send "k $X $Y 1"; sleep 0.25
    send "k $X $Y 0"; sleep 0.45
    got=$(logcat -d -s PadProbe 2>/dev/null | grep -a 'click-down' | tail -1 | sed 's/.*PadProbe: //')
    log "  req=$X,$Y -> $got"
done
exec 3>&-
kill "$HPID" 2>/dev/null
sleep 0.5
setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
sleep 4
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

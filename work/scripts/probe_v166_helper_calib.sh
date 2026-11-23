#!/system/bin/sh
# probe_v166_helper_calib.sh -- c 坐标空间标定：raw natural ↔ 应用逻辑坐标
# 用 P 把光标放到若干逻辑目标点，点击，padtest 报告实际逻辑坐标；
# 同时抓 dumpsys input 的 CursorStatesByDisplay 原始坐标，用于拟合旋转/缩放。
BIN=/data/adb/gpm/gpminput
OUT=/data/local/tmp/v166_calib_helper_out.txt
FIFO=/data/local/tmp/v166_calib_in.fifo
RES=/data/local/tmp/v166_calib.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
log() { echo "$@" | tee -a "$RES"; }
stop_all() {
    for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
    am force-stop $PKG >/dev/null 2>&1
    for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
    for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
    sleep 1
}
: > "$RES"
stop_all
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
log "helper=$(grep -c READY "$OUT") pad=$(pidof $PAD)"
raw_cursor() {
    dumpsys input 2>/dev/null > /data/local/tmp/din_calib.txt
    # 打印 CursorStatesByDisplay 之后 3 行原始 hover 坐标（display 0 分段）
    sed -n '/CursorStatesByDisplay:/,/Display: /p' /data/local/tmp/din_calib.txt | grep -m2 -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([^)]*)' 
}
one() { # $1=label $2=x $3=y
    logcat -c
    send "P $2 $3 2560 1600"
    sleep 1.2
    send "B 0 1"; sleep 0.15; send "B 0 0"
    sleep 1.2
    click=$(logcat -d -s PadProbe 2>/dev/null | grep -a -m1 'MOUSE/click' | sed 's/.*PadProbe: //')
    rc=$(raw_cursor | head -1)
    log "[$1] target=$2,$3 click='$click' raw='$rc'"
    raw_cursor | tail -3 | sed 's/^/   rawline: /' | tee -a "$RES"
}
one center 1280 800
one topright 2540 10
one bottomleft 20 1590
one midleft 40 800
log "== helper OUT tail =="
tail -5 "$OUT" | sed 's/^/  /'
exec 3>&-
sleep 0.3
kill "$HPID" 2>/dev/null
for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
setsid /system/bin/sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 3
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
log "restored helper=$(pidof gpminput) engine=$(pidof $PKG)"
log DONE

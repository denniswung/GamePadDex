#!/system/bin/sh
# probe_v166_helper_drag.sh -- t30 连续拖拽原语真机验证（v1.68 触摸坐标标定后）
#   A) 水平拖拽 +1000px（逻辑 x->面板 Y 轴，用于验收 ABS_MT_POSITION_Y 分步）
#   B) 垂直拖拽 -1000px（验证应用侧 dy 正确、坐标标定正确）
#   C) 安全：无 down 的 move / 参数错误 / 越界夹取
#   D) 掉线保护：>1.5s 无 move 自动 up，之后还能正常点击
BIN=/data/adb/gpm/gpminput
LOG=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v166_drag_out.txt
FIFO=/data/local/tmp/v166_drag_in.fifo
RES=/data/local/tmp/v166_drag.txt
GE=/data/local/tmp/v166_drag_ge.txt
PAD=com.dennis.padtest
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex
log() { echo "$@" | tee -a "$RES"; }
stop_all() {
    for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
    am force-stop $PKG >/dev/null 2>&1
    am force-stop $PAD >/dev/null 2>&1
    for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
    for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
    sleep 1
}
start_all() {
    for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
    sleep 0.5
    setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
    sleep 3
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 2
    log "STARTED helper=$(pidof gpminput) engine=$(pidof $PKG)"
}
slice_from() { tail -n +$(( $1 + 1 )) "$LOG"; }
: > "$RES"
log "== drag $(date) =="
stop_all
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
wm dismiss-keyguard >/dev/null 2>&1
logcat -c
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 3
log "  top: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | tr -d '\r')"
rm -f "$FIFO"; mkfifo "$FIFO"; : > "$OUT"
$BIN < "$FIFO" > "$OUT" 2>/dev/null &
HPID=$!
exec 3> "$FIFO"
sleep 1
send() { echo "$*" >&3; }
log "CHANNEL helper=$HPID ready=$(grep -ac '^READY' "$OUT")"
send "q 2560 1600"; sleep 0.3
logcat -c

# ---- A) 水平拖拽 +1000px / 500ms（3 段），getevent 抓分步
N=$(wc -l < "$LOG"); : > "$GE"
send "d 0 900 800"; sleep 0.4
dev=$(getevent -pl 2>/dev/null | awk '/add device/{d=$NF} /name:.*Gamepad Touch Panel/{print d; exit}')
log "  touch_dev=$dev"
if [ -n "$dev" ]; then
    getevent -lt "$dev" > "$GE" 2>&1 &
    GEPID=$!
    sleep 0.2
fi
send "m 0 400 0 200"; sleep 0.32
send "m 0 350 0 180"; sleep 0.30
send "m 0 250 0 150"; sleep 0.30
send "e 0"; sleep 0.6
[ -n "${GEPID:-}" ] && kill "$GEPID" 2>/dev/null
log "  A helper DRAG lines:"
slice_from "$N" | grep -a -E '^DRAG' | sed 's/^/    /' >> "$RES"
log "  A padtest lines:"
logcat -d -s PadProbe 2>/dev/null | grep -aE 'click-down|drag|swipe' | tail -4 | sed 's/^/    /' >> "$RES"
log "  A getevent posY=$(grep -c 'ABS_MT_POSITION_Y' "$GE" 2>/dev/null) posX=$(grep -c 'ABS_MT_POSITION_X' "$GE" 2>/dev/null)"

# ---- B) 垂直拖拽 -1000px / 500ms（应用侧 dy 应为 -1000）
N=$(wc -l < "$LOG")
logcat -c
send "d 0 1280 1200"; sleep 0.4
send "m 0 0 -400 200"; sleep 0.32
send "m 0 0 -350 180"; sleep 0.30
send "m 0 0 -250 150"; sleep 0.30
send "e 0"; sleep 0.6
log "  B helper DRAG lines:"
slice_from "$N" | grep -a -E '^DRAG' | sed 's/^/    /' >> "$RES"
log "  B padtest lines:"
logcat -d -s PadProbe 2>/dev/null | grep -aE 'click-down|drag|swipe' | tail -4 | sed 's/^/    /' >> "$RES"

# ---- C) 安全：没有 down 的 move / 参数错误 / 越界坐标夹取
N=$(wc -l < "$LOG")
send "m 0 0 -100 100"; sleep 0.3
send "d 0 999"; sleep 0.3
send "d 0 -500 99999"; sleep 0.4
send "e 0"; sleep 0.4
log "  C safety lines:"
slice_from "$N" | grep -a -E '^(DRAG|ERR d|ERR drag)' | sed 's/^/    /' >> "$RES"

# ---- D) 掉线保护：down + 一次小 move 后不再发，等 >1.5s 应自动 up
N=$(wc -l < "$LOG")
send "d 0 1280 900"; sleep 0.3
send "m 0 0 -100 120"; sleep 0.4
sleep 1.8
log "  D auto-up lines:"
slice_from "$N" | grep -a -E '^DRAG' | sed 's/^/    /' >> "$RES"
send "k 1000 900 1"; sleep 0.1; send "k 1000 900 0"; sleep 0.4
log "  D after auto-up tap: $(slice_from "$N" | grep -a -E '^TOUCH' | tail -2 | tr '\n' ' ')"
log "  ERR count=$(grep -ac '^ERR' "$OUT")"
exec 3>&-
sleep 0.3
kill "$HPID" 2>/dev/null
wait "$HPID" 2>/dev/null
start_all
log "== done =="

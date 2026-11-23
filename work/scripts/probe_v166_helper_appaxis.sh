#!/system/bin/sh
# probe_v166_helper_appaxis.sh -- 应用侧证据（v1.66 助手串行队列 + 轴向隔离）
#   1) 单轴推杆：helper 注入条数 == 应用收到的 TOUCH/swipe 条数（没有互相吞并）
#   2) 双轴同阈值（RX=0.36 且 RY=0.36）：只有一个轴真正注入、只有一个区域变化
#   3) 同轴连发：两条都完整到达（串行队列，不丢）
# 用法: adb shell su -c "sh /data/local/tmp/probe_v166_helper_appaxis.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/adb/gpm/helper.log
R=/data/local/tmp/v166_helper_appaxis.txt
log() { echo "$@" | tee -a "$R"; }
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp() { am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
touches() { logcat -d -s PadProbe 2>/dev/null | grep -ac 'TOUCH/swipe'; }
clicks() { logcat -d -s PadProbe 2>/dev/null | grep -ac 'MOUSE/click'; }
swipes() {
    grep -a '^SWIPE ' "$LOG" 2>/dev/null | awk '{ if ($5 != $3) z++; else v++ } END { printf "Z=%d V=%d", z+0, v+0 }'
}
regions() {
    grep -a '^SWIPE ' "$LOG" 2>/dev/null | awk '{ split($3, a, ","); if ($5 != $3) print "Z@" a[2]; else print "V@" a[2] }' | sort | uniq -c | tr '\n' ' '
}
reset() { : > "$LOG"; logcat -c; }
case_run() { # $1=label $2=sleep
    sleep "${2:-1.5}"
    log "  helper: $(swipes)  regions: $(regions)"
    log "  app: TOUCH/swipe=$(touches) MOUSE/click=$(clicks)"
}

: > "$R"
log "== appaxis $(date) =="
wake; sleep 1
startp
log "socket=$(ls -l /data/data/$PKG/files/gpm.sock 2>/dev/null) helper=$(pidof gpminput) engine=$(pidof $PKG)"

log ""
log "[1] 纯纵向 RY=-24000 (0.73) 1200ms —— 期望 helper Z=n, app TOUCH/swipe=n, click=0"
reset; $VG stick 4 -24000 1200 0 >/dev/null 2>&1; case_run a 1.5

log ""
log "[2] 双轴同阈值 RX=+11796 (0.36) + RY=-11796 (0.36) 1200ms —— 期望只有一个轴注入/一个区域"
reset
$VG stick 3 11796 1200 0 >/dev/null 2>&1 &
$VG stick 4 -11796 1200 0 >/dev/null 2>&1 &
wait
case_run b 1.5

log ""
log "[3] 同轴连发 Z 600ms + Z 600ms（间隔 0）—— 期望两条都完整到达（串行，不吞）"
reset
$VG stick 4 -24000 600 0 >/dev/null 2>&1
sleep 0.05
$VG stick 4 -24000 600 0 >/dev/null 2>&1
case_run c 1.5

log ""
log "[4] 同 tick 双轴 RX=+13000 (0.40) + RY=-24000 (0.73) —— 期望只有一个区域"
reset
$VG stick 3 13000 1200 0 >/dev/null 2>&1 &
$VG stick 4 -24000 1200 0 >/dev/null 2>&1 &
wait
case_run d 1.5

log ""
log "== logcat PadProbe tail =="
logcat -d -s PadProbe 2>/dev/null | grep -a 'PadProbe' | tail -8 | sed 's/^/  /'
log "== helper.log SWIPE tail =="
grep -a -E '^(SWIPE|NOTIF)' "$LOG" | tail -10 | sed 's/^/  /'
log "DONE"

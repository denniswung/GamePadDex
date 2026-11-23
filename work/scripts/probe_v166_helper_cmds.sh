#!/system/bin/sh
# probe_v166_helper_cmds.sh -- v1.66 助手侧（gpminput）真机自测
#
# 用法（设备上以 root 运行）：
#   adb push work/scripts/probe_v166_helper_cmds.sh /data/local/tmp/
#   adb shell su -c "sh /data/local/tmp/probe_v166_helper_cmds.sh <mode>"
#
# mode:
#   smoke     全命令 smoke（M/B/S/H/V/Z/O/T/Y/K/G/U/f/p/r/I/L/D/C/t/h/j/A/N/P/R/Q/w/q/k/l/g + u c ?）
#   crosstalk 串行手势：同 tick 双轴 / 同轴连发 / 快速换轴，断言任意时刻只有 1 条 input swipe
#   wake      u 命令：已亮=空操作（负例）；灭屏 → 点亮（Dozing/Asleep → Awake）；3s 去重
#   openapp   w 命令：resolve-activity + am start -n 主路径，PiliPlus / 抖音
#   poison    task 边界缓存投毒 → ≤2s 被真实值纠正
#   gain      g 命令查询/设置 raw→px 增益，且 g_pointer_gain 被 O 真正使用
#   regress   DPAD_CENTER 注入 / SELECT 真实下滑 / WHEEL 左右方向 不回退
#   prep      SWIPE prep 采样（要求每次 < 5000us）
#   all       smoke + crosstalk + wake + openapp + prep（每个 mode 之间重置环境）
#   stop      停掉 watchdog/引擎/helper（测试前）
#   start     恢复正式安装状态（watchdog + 引擎 + helper）
#
# 证据：/data/adb/gpm/helper.log（助手原始日志）+ /data/local/tmp/v166_helper_result.txt
BIN=/data/adb/gpm/gpminput
MODE="${1:-$(cat /data/local/tmp/v166_helper_mode 2>/dev/null)}"
MODE="${MODE:-smoke}"
LOG=/data/adb/gpm/helper.log
OUT=/data/local/tmp/v166_helper_out.txt
ERRF=/data/local/tmp/v166_helper_err.txt
FIFO=/data/local/tmp/v166_helper_in.fifo
RES=/data/local/tmp/v166_helper_result.txt
PKG=com.dennis.dexpad
MOD=/data/adb/modules/gpm_dex

log() { echo "$@" | tee -a "$RES"; }

stop_all() {
    for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
    am force-stop $PKG >/dev/null 2>&1
    for p in $(pgrep -f 'gpminput --socket'); do kill -9 "$p" 2>/dev/null; done
    for p in $(pgrep -f 'gpminput$'); do kill -9 "$p" 2>/dev/null; done
    sleep 1
}

start_all() {
    for p in $(pgrep -f 'gpm_dex/service.sh --supervisor'); do kill -9 "$p" 2>/dev/null; done
    sleep 0.5
    setsid /system/bin/sh "$MOD/service.sh" >/dev/null 2>&1 </dev/null &
    sleep 3
    i=0
    while [ $i -lt 10 ] && [ ! -S /data/data/$PKG/files/gpm.sock ]; do sleep 1; i=$((i+1)); done
    am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
    sleep 2
    log "STARTED helper=$(pidof gpminput) engine=$(pidof $PKG) sock=$(ls -l /data/data/$PKG/files/gpm.sock 2>/dev/null)"
}

open_channel() {
    rm -f "$FIFO"
    mkfifo "$FIFO"
    : > "$OUT"
    : > "$ERRF"
    $BIN < "$FIFO" > "$OUT" 2>"$ERRF" &
    HPID=$!
    exec 3> "$FIFO"
    sleep 1
    log "CHANNEL pid=$HPID ready=$(grep -ac '^READY' "$OUT" 2>/dev/null) err=$(head -c 200 "$ERRF" | tr '\n' ' ')"
}

close_channel() {
    exec 3>&-
    sleep 0.3
    kill "$HPID" 2>/dev/null
    wait "$HPID" 2>/dev/null
    log "CHANNEL closed"
}

send() { echo "$*" >&3; }

send_wait() { send "$@"; sleep 0.25; }

wakefulness() { dumpsys power 2>/dev/null | grep -m1 mWakefulness= | tr -d ' \r'; }

top_activity() { dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | tr -d '\r'; }

# 串行性断言：把 helper.log 里 SWIPE（注入开始）与 SWIPE_DONE 配对
serials() {
    awk '
        /^SWIPE [0-9]/ { if (open == 1) { overlap++; print "  OVERLAP: " $0 } open = 1; starts++ }
        /^SWIPE_DONE/ { if (open == 1) { open = 0; dones++ } else { orphan++ } }
        /^SWIPE_DROP/ { drops++ }
        /^SWIPE_QUEUED/ { queued++ }
        /^NOTIF swipe async/ { starts++; open = 1 }
        /^NOTIF swipe rc=/ { if (open == 1) { open = 0; dones++ } else { orphan++ } }
        END { printf "starts=%d dones=%d overlaps=%d orphan_done=%d drops=%d queued=%d inflight_at_end=%d\n",
                     starts+0, dones+0, overlap+0, orphan+0, drops+0, queued+0, open+0 }
    ' "$LOG"
}

dump_swipe_log() {
    grep -a -E '^(SWIPE|NOTIF swipe)' "$LOG" | tail -16 | sed 's/^/  /'
}

preps() { grep -ao 'prep=[0-9]*us' "$LOG" 2>/dev/null | sed 's/prep=//;s/us//' | tr '\n' ' '; }

do_smoke() {
    : > "$LOG"
    log "== SMOKE =="
    send_wait "M 10 10"; send_wait "M -3 -2"
    send_wait "B 0 1"; send_wait "B 0 0"
    send_wait "B 1 1"; send_wait "B 1 0"
    send_wait "S 3"; send_wait "S -3"
    send_wait "H 2"; send_wait "H -2"
    send_wait "V 0 1024 200 2560 1600 0 1280 800"; sleep 0.7
    send_wait "Z 0 -560 200 2560 1600 30 1280 480"; sleep 0.7
    send_wait "O 2560 1600 0 1 3.25"; sleep 0.8
    send_wait "T"; sleep 0.5
    send_wait "Y 0"; sleep 1.0
    send_wait "K 30 1"; send_wait "K 30 0"
    send_wait "G"; sleep 0.5
    send_wait "U"; sleep 0.4
    send_wait "r 0"; sleep 1.2
    send_wait "I 1"; send_wait "I 0"
    send_wait "D 0 3"; sleep 0.8
    send_wait "C 0 113 81"; sleep 0.5
    send_wait "t"; sleep 1.0
    send_wait "h"; sleep 0.4
    send_wait "j"; sleep 0.6
    send_wait "A 1 0"; sleep 0.4
    send_wait "A 2 0"; sleep 0.4
    send_wait "A 3 0"; sleep 0.4
    send_wait "A 4 0"; sleep 0.4
    send_wait "N"; sleep 1.2
    send_wait "D 0 4"; sleep 0.6
    send_wait "P 1280 800 2560 1600"; sleep 0.8
    send_wait "R"; sleep 0.8
    send_wait "w com.dennis.padtest"; sleep 2.0
    send_wait "q 2560 1600"
    send_wait "k 1200 700 1"; send_wait "k 1200 700 0"
    send_wait "l 1 1280 800"; sleep 0.5; send_wait "l 0 1280 800"
    send_wait "g"; send_wait "g 3.25 3.25"; send_wait "g"
    send_wait "c"; sleep 2.0
    send_wait "?"; sleep 0.8
    send_wait "L"; sleep 1.5
    send_wait "f"; sleep 2.0
    # 电源键最后测：会灭屏
    send_wait "p"; sleep 2.5
    log "  screen after p: $(wakefulness)"
    send_wait "u"; sleep 3.5
    log "  screen after u: $(wakefulness)"
    send_wait "Q"; sleep 0.5
    log "  OUT lines=$(wc -l < "$OUT")"
    log "  ERR lines in OUT:"
    grep -a '^ERR' "$OUT" | sed 's/^/    /'
    log "  ERR count=$(grep -ac '^ERR' "$OUT")"
    log "  helper.log tail:"
    tail -6 "$LOG" | sed 's/^/    /'
}

do_crosstalk() {
    log "== CROSSTALK (serialized gesture) =="
    # case 1: 同一 tick 双轴（DIAG 场景 C/E 的助手侧输入）
    : > "$LOG"
    send "Z 0 -560 200 2560 1600 30 1280 480"
    send "V 0 1024 200 2560 1600 0 1280 800"
    sleep 1.5
    log "-- case1 same-tick Z+V (expect 1 injection + 1 SWIPE_DROP) --"
    dump_swipe_log
    log "  $(serials)"

    # case 2: 同轴连发（翻页连发 / 快滑共用窗口）
    : > "$LOG"
    send "Z 0 -560 200 2560 1600 30 1280 480"
    sleep 0.03
    send "Z 0 -560 200 2560 1600 30 1280 480"
    sleep 2.0
    log "-- case2 same-axis burst Z x2 (expect serial: 1 injection + QUEUED, then second) --"
    dump_swipe_log
    log "  $(serials)"

    # case 3: 快速换轴 100ms（保护窗）
    : > "$LOG"
    i=0
    while [ $i -lt 2 ]; do
        send "V 0 1024 200 2560 1600 0 1280 800"
        sleep 0.1
        send "Z 0 -560 200 2560 1600 30 1280 480"
        sleep 0.1
        i=$((i+1))
    done
    sleep 2.5
    log "-- case3 alternating V/Z @100ms (expect never 2 in flight) --"
    dump_swipe_log
    log "  $(serials)"

    # case 4: 滑动在飞时按 SELECT（N 也走队列，不得并发）
    : > "$LOG"
    send "Z 0 -560 200 2560 1600 30 1280 480"
    sleep 0.05
    send "N"
    sleep 2.5
    log "-- case4 swipe + N in flight (expect serialized) --"
    dump_swipe_log
    log "  $(serials)"

    # case 5: prep 采样
    : > "$LOG"
    i=0
    while [ $i -lt 6 ]; do
        send "Z 0 -560 200 2560 1600 30 1280 480"
        sleep 0.8
        i=$((i+1))
    done
    sleep 1.5
    log "-- case5 prep samples --"
    log "  preps=[$(preps)]"
    log "  max_prep=$(grep -ao 'prep=[0-9]*' "$LOG" | sed 's/prep=//' | sort -n | tail -1)"
}

do_wake() {
    log "== WAKE =="
    : > "$LOG"
    log "  before: $(wakefulness)"
    # 负例：屏幕已亮 → 必须空操作（uinput=0 / 无输入事件）
    send "u"; sleep 3.5
    log "  negative case logs:"
    grep -a '^WAKE' "$LOG" | sed 's/^/    /'
    log "  negative uinput=1 count=$(grep -ac 'uinput=1' "$LOG")"
    log "  after negative: $(wakefulness)"

    # 正例：电源键灭屏 → u 点亮
    : > "$LOG"
    send "p"; sleep 3.0
    log "  screen off via p: $(wakefulness)"
    send "u"; sleep 4.0
    log "  positive case logs:"
    grep -a '^WAKE' "$LOG" | sed 's/^/    /'
    log "  after positive: $(wakefulness)"

    # 去重：3s 内第二次 u 必须 dedup
    : > "$LOG"
    send "u"; sleep 0.3; send "u"; sleep 3.0
    log "  dedupe logs:"
    grep -a '^WAKE' "$LOG" | sed 's/^/    /'
    log "  after dedupe: $(wakefulness)"
}

do_openapp() {
    log "== OPEN_APP =="
    : > "$LOG"
    for PK in com.example.piliplus com.ss.android.ugc.aweme; do
        log "-- $PK --"
        send "w $PK"
        sleep 8
        grep -a "OPEN_APP $PK" "$LOG" | sed 's/^/  /'
        log "  top: $(top_activity)"
    done
    log "  fallback_pkg_count=$(grep -ac 'fallback=pkg' "$LOG")"
    log "  monkey_count=$(grep -ac 'OPEN_APP .* monkey' "$LOG")"
    log "  resolve_failed_count=$(grep -ac 'resolve_failed=1' "$LOG")"
}

do_cursor() {
    log "== CURSOR logical (multi-display) =="
    : > "$LOG"
    am force-stop com.dennis.padtest >/dev/null 2>&1
    am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
    sleep 2.5
    for t in 1280,800 40,800 2540,10 20,1590 1280,1590; do
        X=${t%,*}
        Y=${t#*,}
        send "P $X $Y 2560 1600"; sleep 1.2
        logcat -c
        send "B 0 1"; sleep 0.15; send "B 0 0"; sleep 1.0
        click=$(logcat -d -s PadProbe 2>/dev/null | grep -a -m1 'MOUSE/click' | sed 's/.*PadProbe: //')
        send "c"; sleep 1.5
        cv=$(grep -a '^CURSOR ' "$LOG" | tail -1)
        log "  target=$X,$Y click='$click'"
        log "    c: $cv"
    done
    # 负例：找不到光标时格式
    log "  all CURSOR lines:"
    grep -a '^CURSOR ' "$LOG" | sed 's/^/    /'
}

do_capidle() {
    log "== CAP semantics: pointer visible vs idle-hidden (t11) =="
    : > "$LOG"
    # 1) 指针可见
    send "j"; sleep 0.8
    send "?"; sleep 1.5
    log "  [visible] CAP/INFO:"
    grep -a -E '^(CAP|INFO pointer)' "$LOG" | sed 's/^/    /'
    log "  [visible] CAP zero count=$(grep -a '^CAP ' "$LOG" | awk '$3 == 0' | wc -l)"
    # 2) 空闲隐藏（h 销毁虚拟鼠标设备，等价 app 的 8s 空闲隐藏）
    : > "$LOG"
    send "h"; sleep 1.0
    send "?"; sleep 1.5
    log "  [hidden] CAP/INFO:"
    grep -a -E '^(CAP|INFO pointer)' "$LOG" | sed 's/^/    /'
    log "  [hidden] CAP zero count=$(grep -a '^CAP ' "$LOG" | awk '$3 == 0' | wc -l)"
    hidden_zero=$(grep -a '^CAP ' "$LOG" | awk '$3 == 0' | tr '\n' ' ')
    log "  [hidden] CAP zero lines: ${hidden_zero:-none}"
    # 3) 恢复可见，CAP 必须与 hidden 一致
    : > "$LOG"
    send "j"; sleep 1.0
    send "?"; sleep 1.5
    log "  [visible-again] CAP/INFO:"
    grep -a -E '^(CAP|INFO pointer)' "$LOG" | sed 's/^/    /'
    log "  [visible-again] CAP zero count=$(grep -a '^CAP ' "$LOG" | awk '$3 == 0' | wc -l)"
    log "  selftest begin/end=$(grep -ac '^SELFTEST begin' "$LOG")/$(grep -ac '^SELFTEST end' "$LOG")  ERR=$(grep -ac '^ERR' "$LOG")"
}

do_selftest() {
    log "== SELFTEST capability semantics (t10) =="
    : > "$LOG"
    send "?"; sleep 2.0
    log "  CAP/INFO/SELFTEST lines:"
    grep -a -E '^(CAP|INFO|SELFTEST)' "$LOG" | sed 's/^/    /'
    log "  CAP zero lines:"
    grep -a '^CAP ' "$LOG" | awk '$3 == 0 { print "    " $0 }'
    log "  CAP zero count=$(grep -a '^CAP ' "$LOG" | awk '$3 == 0' | wc -l)"
    log "  selftest begin/end=$(grep -ac '^SELFTEST begin' "$LOG")/$(grep -ac '^SELFTEST end' "$LOG")"
    log "  ERR count=$(grep -ac '^ERR' "$LOG")"

    # K 组快速验证：u / c / g / P（t4 的 K 组四条）
    : > "$LOG"
    send "P 1280 800 2560 1600"; sleep 1.2
    send "c"; sleep 1.5
    send "g"; sleep 0.5
    send "g 0 4.68"; sleep 0.4
    send "c"; sleep 1.2
    send "g"; sleep 0.4
    send "u"; sleep 3.0
    log "  K group (P/c/g/u) logs:"
    grep -a -E '^(WAKE|CURSOR|CURSORQ|GAIN|POSPTR|CENTER)' "$LOG" | sed 's/^/    /'
}

do_poison() {
    log "== BOUNDS CACHE POISON (threshold ≤2.5s, samples 2.0/2.3/2.5s) =="
    for W in 2.0 2.3 2.5; do
        # 先建立正确缓存，再投毒
        : > "$LOG"
        send "Z 0 -560 200 2560 1600 30 1280 480"; sleep 1.2
        echo '- 600 240 1200 800 2560 1600' > /data/adb/gpm/taskbounds-0.txt
        : > "$LOG"
        send "Z 0 -560 200 2560 1600 30 1280 480"      # 立刻：应命中投毒值
        sleep "$W"
        send "Z 0 -560 200 2560 1600 30 1280 480"      # W 秒后：应已纠正
        sleep 1.2
        log "  [wait ${W}s]"
        grep -a '^SWIPE ' "$LOG" | sed 's/^/    /'
        log "    cache=$(cat /data/adb/gpm/taskbounds-0.txt 2>/dev/null)"
    done
    log "  legacy mirror: $(cat /data/adb/gpm/taskbounds.txt 2>/dev/null)"
}

do_gain() {
    log "== GAIN QUERY/SET =="
    : > "$LOG"
    send "g"; sleep 0.5
    send "g 3.25 3.25"; sleep 0.5
    # g 0 <ptr>：center 归零 → effective 用实测 ptr 增益 4.68
    send "g 0 4.68"; sleep 0.5
    send "g"; sleep 0.5
    # 不带 gain 的 O：使用 g_pointer_gain（4.68）→ CENTER(steps+gain 4.68)
    send "O 2560 1600 0 1"; sleep 1.5
    send "g 3.25 3.25"; sleep 0.4
    send "O 2560 1600 0 1 3.25"; sleep 1.5
    send "g 3.25 3.25"; sleep 0.4
    log "  GAIN/CENTER lines:"
    grep -a -E '^(GAIN|CENTER)' "$LOG" | sed 's/^/    /'
}

do_regress() {
    log "== REGRESSION: DPAD_CENTER / SELECT / WHEEL dir =="
    : > "$LOG"
    # DPAD_CENTER：Android 23 -> Linux ENTER(28)（d-pad 粘性导航按 A 的注入）
    send "D 0 23"; sleep 0.6
    # d-pad 方向键（App 的 A 命令）
    send "A 1 0"; sleep 0.4
    send "A 2 0"; sleep 0.4
    # SELECT：真实下滑手势展开通知栏
    send "N"; sleep 1.5
    send "D 0 4"; sleep 0.6
    # WHEEL 方向（v1.62 约定：正=上/右，负=下/左）
    send "H 3"; sleep 0.4; send "H -3"; sleep 0.4
    send "S 2"; sleep 0.4; send "S -2"; sleep 0.4
    log "  evidence:"
    grep -a -E '^(KEYUIN|ARROW|NOTIF|WHEEL|PAD )' "$LOG" | sed 's/^/    /'
}
do_prep() {
    log "== PREP =="
    : > "$LOG"
    i=0
    while [ $i -lt 10 ]; do
        send "Z 0 -560 200 2560 1600 30 1280 480"
        sleep 0.7
        i=$((i+1))
    done
    sleep 1.5
    log "  preps=[$(preps)]"
    log "  max_prep=$(grep -ao 'prep=[0-9]*' "$LOG" | sed 's/prep=//' | sort -n | tail -1)"
    log "  $(serials)"
}

: > "$RES"
log "== probe_v166_helper_cmds mode=$MODE $(date) =="
stop_all
open_channel
case "$MODE" in
    smoke) do_smoke ;;
    crosstalk) do_crosstalk ;;
    wake) do_wake ;;
    openapp) do_openapp ;;
    poison) do_poison ;;
    gain) do_gain ;;
    regress) do_regress ;;
    cursor) do_cursor ;;
    selftest) do_selftest ;;
    capidle) do_capidle ;;
    prep) do_prep ;;
    all)
        do_smoke
        do_crosstalk
        do_wake
        do_openapp
        do_poison
        do_gain
        do_regress
        do_prep
        ;;
    *) log "unknown mode $MODE" ;;
esac
close_channel
if [ "$MODE" = "stop" ]; then
    log "left stopped"
else
    start_all
fi
log "== done =="

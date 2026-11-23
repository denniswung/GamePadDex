#!/system/bin/sh
# probe_v166_helper_cpu.sh -- t13/R1：release helper 60s 进程级 CPU 复测（新 vs v1.65）
# 口径：/proc/<pid>/stat 的 utime+stime（进程自身，用户态+内核态）；
#       cutime+cstime 是「已被本进程回收的子进程」累计 CPU（本助手会 fork dumpsys/input 子进程，
#       它们被 waitpid 回收后计入 cutime/cstime），单独列出，不混进进程自身口径。
# 条件：引擎已连接、无输入、屏幕常亮；两版本同一方法、同一 60s 窗口长度。
R=/data/local/tmp/v166_helper_cpu.txt
LOG=/data/adb/gpm/helper.log
NEW=/data/local/tmp/gpminput_v166
OLD=/data/local/tmp/gpminput_v165_module.bak
HASH_NEW=1bf7306f38421c574bb8fa39ffd327ccad487a9a1f40662dac7381f710b6f4bf
HASH_OLD=18268d3ba4dc9506944e8c1a0a6737688b4c354789697de7a19083193444b1dd
log() { echo "$@" | tee -a "$R"; }
clk=$(getconf CLK_TCK 2>/dev/null)
[ -z "$clk" ] && clk=100
fields() { awk '{print $14, $15, $16, $17}' /proc/$1/stat 2>/dev/null; }
measure() { # $1=label $2=pid $3=secs
    pid=$2; secs=$3
    set -- $(fields "$pid")
    u0=$1; s0=$2; cu0=$3; cs0=$4
    sleep "$secs"
    set -- $(fields "$pid")
    u1=$1; s1=$2; cu1=$3; cs1=$4
    if [ -z "$u1" ]; then log "  [$1] pid $pid gone"; return; fi
    self_ticks=$(( (u1 - u0) + (s1 - s0) ))
    child_ticks=$(( (cu1 - cu0) + (cs1 - cs0) ))
    log "  [$1] pid=$pid secs=$secs clk_tck=$clk utime+stime=${self_ticks}ticks cutime+cstime=${child_ticks}ticks"
    log "       process_cpu=$(awk -v t=$self_ticks -v s=$secs -v h=$clk 'BEGIN{printf "%.2f%%", t/h*100/s}')   children_cpu=$(awk -v t=$child_ticks -v s=$secs -v h=$clk 'BEGIN{printf "%.2f%%", t/h*100/s}')"
}
pid_ok() { # $1=expected hash $2=label
    h=$(sha256sum /data/adb/gpm/gpminput | awk '{print $1}')
    if [ "$h" = "$1" ]; then log "  $2 hash OK ($h)"; else log "  $2 hash MISMATCH got=$h want=$1"; fi
}
install_bin() { # $1=src
    cp -f "$1" /data/adb/gpm/gpminput
    cp -f "$1" /data/adb/modules/gpm_dex/gpminput
    chmod 755 /data/adb/gpm/gpminput /data/adb/modules/gpm_dex/gpminput
}
restart_helper() {
    pkill -f 'gpminput --socket' 2>/dev/null
    sleep 1
    i=0
    while [ $i -lt 15 ]; do
        pidof gpminput >/dev/null 2>&1 && break
        sleep 1; i=$((i+1))
    done
    sleep 6            # 等引擎重连 + READY（两边同一条件）
}
: > "$R"
log "== helper 60s process CPU (t13/R1) $(date) =="
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
pid_ok $HASH_NEW "A/new"
NHPID=$(pidof gpminput)
log "  A/new pid=$NHPID engine=$(pidof com.dennis.dexpad)"
measure "A: v1.66 helper (release)" "$NHPID" 60

install_bin "$OLD"
restart_helper
pid_ok $HASH_OLD "B/old"
OHPID=$(pidof gpminput)
log "  B/old pid=$OHPID engine=$(pidof com.dennis.dexpad)"
measure "B: v1.65 helper (baseline)" "$OHPID" 60

install_bin "$NEW"
restart_helper
pid_ok $HASH_NEW "C/restored"
log "  C/restored pid=$(pidof gpminput) engine=$(pidof com.dennis.dexpad)"
log DONE

#!/system/bin/sh
# v166_cpu60.sh <label> -- 60s idle CPU of com.dennis.dexpad, process-level (same method as t15 H3)
#   process  = /proc/<pid>/stat fields 14+15 (utime+stime) delta / 60s   <- primary, "进程级"
#   child    = fields 16+17 (cutime+cstime) delta / 60s                 <- must be ~0: no child inherits CPU
#   threads  = sum over /proc/<pid>/task/*/stat fields 14+15            <- thread-level, includes short-lived
#                                                                          Kotlin/JIT helper threads
PKG=com.dennis.dexpad
LABEL="${1:-run}"
wake() { input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
am force-stop com.dennis.padtest >/dev/null 2>&1
cmd statusbar collapse >/dev/null 2>&1
sleep 20   # let the idle loop drop 8ms -> 16ms before sampling
PID=$(pidof $PKG)
if [ -z "$PID" ]; then echo "$LABEL: app not running"; exit 1; fi
P0=$(awk '{print $14+$15}' /proc/$PID/stat); C0=$(awk '{print $16+$17}' /proc/$PID/stat)
T0=$(for t in /proc/$PID/task/*; do awk '{print $14+$15}' "$t/stat" 2>/dev/null; done | awk '{s+=$1} END{print s+0}')
NTH0=$(ls -d /proc/$PID/task/* 2>/dev/null | wc -l)
sleep 60
P1=$(awk '{print $14+$15}' /proc/$PID/stat); C1=$(awk '{print $16+$17}' /proc/$PID/stat)
T1=$(for t in /proc/$PID/task/*; do awk '{print $14+$15}' "$t/stat" 2>/dev/null; done | awk '{s+=$1} END{print s+0}')
NTH1=$(ls -d /proc/$PID/task/* 2>/dev/null | wc -l)
per=$(awk -v a="$P0" -v b="$P1" 'BEGIN{printf "%.2f",(b-a)/60.0}')
chi=$(awk -v a="$C0" -v b="$C1" 'BEGIN{printf "%.2f",(b-a)/60.0}')
thr=$(awk -v a="$T0" -v b="$T1" 'BEGIN{printf "%.2f",(b-a)/60.0}')
echo "$LABEL: pid=$PID threads=${NTH0}->${NTH1} process_utime_stime=${per}% thread_sum=${thr}% cutime_cstime=${chi}%"
echo "$LABEL: raw P0=$P0 P1=$P1 C0=$C0 C1=$C1 T0=$T0 T1=$T1"
echo "$LABEL: apk=$(sha256sum $(pm path $PKG | head -1 | sed 's/package://') | cut -d' ' -f1) ver=$(dumpsys package $PKG | grep -m1 versionName | sed 's/.*=//')"

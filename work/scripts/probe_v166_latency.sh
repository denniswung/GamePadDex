#!/system/bin/sh
# probe_v166_latency.sh -- 事件→动作 时延 + 引擎 CPU（v1.65 基线 / v1.66 优化后 通用）
#  1) 12 次 A 键：logcat 同一时钟里 "button a down" -> PadProbe "MOUSE/click-down" 的时间差
#  2) 30s 空闲（指针已隐藏）引擎进程 CPU（/proc/<pid>/stat utime+stime）
#  3) v1.66 自报帧耗时 perf tick（旧版没有该日志）
# 用法：adb push work/scripts/probe_v166_latency.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_latency.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_latency.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
cpu(){ # $1 pid -> utime+stime ticks
  awk '{print $14+$15}' /proc/$1/stat 2>/dev/null; }

wake
am force-stop $PAD >/dev/null 2>&1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
cmd statusbar collapse >/dev/null 2>&1
sleep 0.5
L "=== 0. 环境 ==="
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  pid=$(pidof $PKG) focus=$(dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | sed 's/.*mCurrentFocus=//;s/ .*//')"
# 先点一次确认链路（同时唤醒指针）
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
L "  warmup_click=$(logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down')"

L ""
L "=== 1. 事件→动作时延（12 次 A 单击，ms）==="
i=0
while [ $i -lt 12 ]; do
  i=$((i+1))
  logcat -c
  $VG key 304 60 0 >/dev/null 2>&1
  sleep 0.35
  D=$(logcat -d -v threadtime -s DexPad PadProbe 2>/dev/null | awk '
    /button a down/ { if (a==0) { split($2,t,":"); a=t[1]*3600+t[2]*60+t[3] } }
    /MOUSE\/click-down/ { if (a>0 && b==0) { split($2,t,":"); b=t[1]*3600+t[2]*60+t[3]; printf "%.0f", (b-a)*1000; exit } }
  ')
  L "  #$i ${D:-n/a} ms"
done

L ""
L "=== 2. 30s 空闲 CPU（引擎进程；指针空闲隐藏后）==="
sleep 9
PID=$(pidof $PKG)
if [ -n "$PID" ]; then
  C0=$(cpu $PID); sleep 30; C1=$(cpu $PID)
  L "  pid=$PID ticks=$C0->$C1"
  awk -v a="$C0" -v b="$C1" 'BEGIN{ d=b-a; printf "  cpu=%.2f%% (%.0f ticks/30s @100Hz)\n", d/30.0, d }' | tee -a "$LOG"
else
  L "  pid missing"
fi

L ""
L "=== 3. 引擎自报帧耗时（v1.66 才有）==="
L "  perf=$(logcat -d -s DexPad 2>/dev/null | grep -a 'perf tick' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  lat=$(logcat -d -s DexPad 2>/dev/null | grep -a 'lat n=' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  prefs_guide_debug_lines=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'prefs guide')"
L "DONE $(getprop ro.serialno)"

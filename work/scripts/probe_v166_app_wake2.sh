#!/system/bin/sh
# probe_v166_app_wake2.sh -- 摇杆唤醒（不被助手"接入点亮"干扰的版本）
#   助手在虚拟手柄 *新接入* 时会点亮屏幕（WAKE_CONNECT），vgpad 每次都新建设备，
#   所以旧脚本测不到 App 的 u 命令。这里用"一个常驻设备 + sendevent 改轴"来模拟
#   "手柄一直连着、人推摇杆"：灭屏后小幅/慢速不唤醒，大幅快速 200ms 后唤醒。
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_wake2.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wf(){ dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//;s/ .*//'; }
inter(){ [ "$(wf)" = "Awake" ]; }
sendabs(){ # $1 eventNode $2 axis(0=X) $3 value
  sendevent "$1" 3 "$2" "$3" 2>/dev/null
  sendevent "$1" 0 0 0 2>/dev/null
}
wakelog(){ logcat -d -s DexPad 2>/dev/null | grep -aE 'wake (sent|skip)' | tail -${1:-4} | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
wakeresp(){ logcat -d -s DexPad 2>/dev/null | grep -a 'helper WAKE' | tail -${1:-4} | sed 's/^.*DexPad *: //' | tr '\n' '|'; }

wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
wake
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5

# 常驻虚拟手柄（60s 不动），只接入一次（避开助手的接入点亮）
$VG stick 0 0 60000 0 >/dev/null 2>&1 &
VGPID=$!
sleep 2.5
NODE=$(getevent -lp 2>/dev/null | awk '/^add device/{d=$4} /Virtual Test Gamepad/{print d}' | tail -1)
L "=== 0. 常驻手柄 ==="
L "  vgpad_pid=$VGPID node=$NODE wakefulness=$(wf) version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  prefs=$(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
if [ -z "$NODE" ]; then L "NO EVENT NODE"; kill $VGPID 2>/dev/null; exit 3; fi

# 灭屏（这个设备已经连上，助手不会再因接入而点亮）
L ""
L "=== 1. 灭屏（常驻手柄不重连）==="
input keyevent KEYCODE_SLEEP >/dev/null 2>&1
sleep 3
W0=$(wf)
L "  after_sleep wakefulness=$W0"

L ""
L "=== 2. 负例 A：小幅 0.37 持续 1.4s（阈值 0.80）==="
logcat -c
sendabs "$NODE" 0 12000; sleep 1.4; sendabs "$NODE" 0 0; sleep 1.2
L "  before=$W0 after=$(wf) | wake_log=$(wakelog 3) | rise=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake riseCross' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"

L ""
L "=== 3. 负例 B：中等 0.73 持续 1.4s（仍低于阈值）==="
[ "$(wf)" = "Awake" ] && { input keyevent KEYCODE_SLEEP; sleep 2.5; }
WB=$(wf); logcat -c
sendabs "$NODE" 0 24000; sleep 1.4; sendabs "$NODE" 0 0; sleep 1.2
L "  before=$WB after=$(wf) | wake_log=$(wakelog 3) | rise=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake riseCross' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"

L ""
L "=== 4. 正例：大幅快速 0.92（200ms 保持后触发）==="
[ "$(wf)" = "Awake" ] && { input keyevent KEYCODE_SLEEP; sleep 3; }
WC=$(wf); logcat -c
sendabs "$NODE" 0 30000
sleep 0.25
L "  +250ms wakefulness=$(wf) (期望已 Awake)"
sleep 1.6
sendabs "$NODE" 0 0
L "  before=$WC after=$(wf) | wake_log=$(wakelog 5)"
L "  riseCross=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake riseCross' | tail -2 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "  helper_resp=$(wakeresp 6)"
L "  helper_log=$(grep -a 'WAKE' /data/adb/gpm/helper.log 2>/dev/null | tail -3 | tr '\n' '|')"

L ""
L "=== 5. 正例复核：再次灭屏 + 反向大幅 0.92 ==="
input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 3
WD=$(wf); logcat -c
sendabs "$NODE" 0 -30000
sleep 1.8
sendabs "$NODE" 0 0
L "  before=$WD after=$(wf) | wake_log=$(wakelog 5)"
L "  helper_resp=$(wakeresp 6)"

kill $VGPID 2>/dev/null
sleep 0.5
L "DONE $(getprop ro.serialno) wakefulness=$(wf)"

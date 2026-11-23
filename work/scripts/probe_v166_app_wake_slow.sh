#!/system/bin/sh
# 慢速大幅（0.24→0.85 用 1.5s 爬升）不应唤醒；同一常驻设备、灭屏
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_wake_slow.log
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wf(){ dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//;s/ .*//'; }
sendabs(){ sendevent "$1" 3 0 "$2" 2>/dev/null; sendevent "$1" 0 0 0 2>/dev/null; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

if pidof vgpad >/dev/null 2>&1; then echo BUSY; exit 2; fi
wake
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 1.5
$VG stick 0 0 40000 0 >/dev/null 2>&1 &
VGPID=$!
sleep 2.5
NODE=$(getevent -lp 2>/dev/null | awk '/^add device/{d=$4} /Virtual Test Gamepad/{print d}' | tail -1)
L "node=$NODE pid=$VGPID version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
input keyevent KEYCODE_SLEEP >/dev/null 2>&1
sleep 3
W0=$(wf); logcat -c
L "before_ramp=$W0"
for v in 8000 12000 16000 20000 24000 27000 28500 30000; do
  sendabs "$NODE" "$v"
  sleep 0.3
  L "  v=$v ($((v*100/32767))%) wakefulness=$(wf)"
done
sleep 1.0
sendabs "$NODE" 0
sleep 1.2
L "after_ramp=$(wf) | wake_log=$(logcat -d -s DexPad 2>/dev/null | grep -aE 'wake (sent|skip)' | tail -5 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "riseCross=$(logcat -d -s DexPad 2>/dev/null | grep -a 'wake riseCross' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
kill $VGPID 2>/dev/null
L "DONE"

#!/system/bin/sh
# probe_v166_app_wake.sh -- v1.66 App 侧真机验收 D：摇杆唤醒（新功能6）
#   正例：灭屏后大幅快速推左摇杆 -> 助手 u -> mWakefulness 变 Awake
#   负例：小幅（0.37/0.45）与中等幅度（0.73，低于阈值 0.80）持续推 -> 不唤醒
# 用法：adb push work/scripts/probe_v166_app_wake.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_app_wake.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_wake.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
sleepdev(){ input keyevent KEYCODE_SLEEP >/dev/null 2>&1; sleep 2.5; }
wf(){ dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | sed 's/.*mWakefulness=//;s/ .*//'; }
inter(){ dumpsys power 2>/dev/null | grep -m1 'mWakefulness=' | grep -c 'Awake'; }
wakelog(){ logcat -d -s DexPad 2>/dev/null | grep -aE 'wake (sent|skip)' | tail -${1:-3} | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
wakeresp(){ logcat -d -s DexPad 2>/dev/null | grep -a 'helper WAKE' | tail -${1:-4} | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
stick(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.2; }
prefs(){ cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }

wake
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
L "=== 0. 环境 ==="
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  prefs=$(prefs)"
L "  wakefulness=$(wf) helper=$(md5sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)"
L "  wake_prefs: $(cat /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | grep -oE 'wake_[a-z_]+" value="[0-9]+"' | tr '\n' ' ')"

L ""
L "=== 1. 负例 A：小幅 0.37 持续 1.2s（幅度低于阈值 0.80）==="
sleepdev
W0=$(wf); logcat -c
stick 0 12000 1200
sleep 1.6
L "  before=$W0 after=$(wf) | wake_log=$(wakelog 3) | helper=$(wakeresp 2)"

L ""
L "=== 2. 负例 B：中等幅度 0.73 持续 1.4s（仍低于阈值）==="
[ "$(inter)" = "0" ] || sleepdev
W1=$(wf); logcat -c
stick 0 24000 1400
sleep 1.6
L "  before=$W1 after=$(wf) | wake_log=$(wakelog 3) | helper=$(wakeresp 2)"

L ""
L "=== 3. 正例：大幅快速 0.92 持续 0.6s（灭屏）==="
[ "$(inter)" = "0" ] || sleepdev
W2=$(wf); logcat -c
$VG stick 0 30000 600 0 >/dev/null 2>&1
sleep 2.5
L "  before=$W2 after=$(wf) | wake_log=$(wakelog 4)"
L "  helper_resp=$(wakeresp 6)"
L "  helper_log=$(grep -a 'WAKE' /data/adb/gpm/helper.log 2>/dev/null | tail -4 | tr '\n' '|')"
L "  auth_keyguard=$(dumpsys window 2>/dev/null | grep -m1 mDreamingLockscreen | tr -d '\n')"

L ""
L "=== 4. 正例复核：再次灭屏 + 反向推杆 0.92 ==="
[ "$(inter)" = "1" ] || wake
sleepdev
W3=$(wf); logcat -c
$VG stick 0 -30000 600 0 >/dev/null 2>&1
sleep 2.5
L "  before=$W3 after=$(wf) | wake_log=$(wakelog 3) | helper=$(wakeresp 4)"

L "DONE $(getprop ro.serialno)"

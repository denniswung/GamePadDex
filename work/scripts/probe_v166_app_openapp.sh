#!/system/bin/sh
# probe_v166_app_openapp.sh -- v1.66 App 侧真机验收 C：
#  1) Y+上 打开 PiliPlus（com.example.piliplus）、Y+下 打开抖音（com.ss.android.ugc.aweme）
#     —— 走 open_app 动作 + 助手组件解析启动（前台组件验证）
#  2) 不覆盖用户已有自定义映射（预置 mix_10 自定义后 Y+上 不再打开 PiliPlus）
#  3) 回归：d-pad 粘性+A=DPAD_CENTER / X 双击 400ms 多任务 / X+LB 上一页 / X+RB 下一页 /
#           空闲隐藏原地隐形恢复 / SELECT 真实下滑手势通知栏 / Y 单击 Home
# 用法：adb push work/scripts/probe_v166_app_openapp.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_app_openapp.sh"
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_app_openapp.log
HL=/data/adb/gpm/helper.log
PREF=/data/misc/*/prefs/$PKG/dexpad.xml

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.0; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
focus(){ dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | sed 's/.*mCurrentFocus=//;s/ .*//'; }
clickxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
entry(){ # $1 = "key_enter" | "app_switch" | "mouse_click"
  case $1 in
    key_enter) logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_ENTER' ;;
    app_switch) logcat -d -s PadProbe 2>/dev/null | grep -c 'KEY/key-down KEYCODE_APP_SWITCH' ;;
    mouse_click) logcat -d -s PadProbe 2>/dev/null | grep -c 'MOUSE/click-down' ;;
  esac; }
dx(){ logcat -d -s DexPad 2>/dev/null | grep -aE "$1" | tail -"${2:-4}" | sed 's/^.*DexPad *: //' | tr '\n' '|'; }
hl(){ grep -aE "$1" "$HL" 2>/dev/null | tail -"${2:-4}" | tr '\n' '|'; }
setpref(){ am broadcast -a com.dennis.dexpad.DEBUG -n $PKG/.DebugReceiver "$@" >/dev/null 2>&1; sleep 0.6; }
yup(){ $VG keyvhat 308 -1 500 2600 >/dev/null 2>&1; sleep 2.5; }
ydown(){ $VG keyvhat 308 1 500 2600 >/dev/null 2>&1; sleep 2.5; }

wake; startp
L "=== 0. 环境 ==="
L "  version=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')"
L "  apk_sha=$(sha256sum $(pm path $PKG | sed 's/package://') | cut -d' ' -f1)"
L "  helper_sha=$(sha256sum /data/adb/gpm/gpminput | cut -d' ' -f1)"
L "  prefs=$(cat $PREF 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"
L "  installed: piliplus=$(pm list packages com.example.piliplus | wc -l) douyin=$(pm list packages com.ss.android.ugc.aweme | wc -l)"
L "  focused=$(focus) top=$(top)"

L ""
L "=== 1. Y+上 -> PiliPlus ==="
: > "$HL"; logcat -c
yup
L "  top=$(top) focus=$(focus)"
L "  app_log: $(dx 'mix 1[01]|open app' 6)"
L "  helper:  $(hl 'OPEN_APP' 4)"

L ""
L "=== 2. Y+下 -> 抖音 ==="
: > "$HL"; logcat -c
ydown
L "  top=$(top) focus=$(focus)"
L "  app_log: $(dx 'mix 1[01]|open app' 6)"
L "  helper:  $(hl 'OPEN_APP' 4)"

L ""
L "=== 3. 不覆盖用户已有自定义（预置 mix_10 = x+rb -> wheel_left，再按 Y+上）==="
cp $PREF /data/local/tmp/dexpad_prefs_backup.xml 2>/dev/null
setpref --es pref mix_10_keys --es sval x+rb
setpref --es pref mix_10_action --es sval wheel_left
setpref --es pref mix_10_value --es sval alt+tab
L "  custom prefs=$(grep -o 'name="mix_10_[a-z_]*" value="[^"]*"' $PREF 2>/dev/null | tr '\n' ' ')"
L "  prefs_readback: keys=$(grep -o 'name="mix_10_keys" value="[^"]*"' $PREF 2>/dev/null) action=$(grep -o 'name="mix_10_action" value="[^"]*"' $PREF 2>/dev/null)"
: > "$HL"; logcat -c
yup
L "  top=$(top) (期望不是 piliplus)"
L "  app_log: $(dx 'mix 1[01]|open app' 6)"
L "  OPEN_APP_in_helper=$(grep -ac 'OPEN_APP' "$HL" 2>/dev/null)"
# 恢复原始 prefs 字节
am force-stop $PKG >/dev/null 2>&1
OWNER=$(stat -c '%u:%g' $PREF 2>/dev/null)
cp /data/local/tmp/dexpad_prefs_backup.xml $PREF 2>/dev/null
[ -n "$OWNER" ] && chown "$OWNER" $PREF 2>/dev/null
chmod 660 $PREF 2>/dev/null
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
L "  restored_prefs=$(cat $PREF 2>/dev/null | tr -d '\n' | sed 's/  */ /g')"

L ""
L "=== 4. 回归：d-pad 粘性导航 + A=DPAD_CENTER ==="
startp
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
L "  mouse_click=$(entry mouse_click) key_enter=$(entry key_enter) | $(dx 'A -> DPAD_CENTER|native navigation' 3)"
# 推一下左摇杆应退出导航，A 恢复鼠标点击
$VG stick 0 20000 250 0 >/dev/null 2>&1; sleep 0.5
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
L "  after-stick: mouse_click=$(entry mouse_click) key_enter=$(entry key_enter) | $(dx 'native navigation OFF' 2)"

L ""
L "=== 5. 回归：X 双击 400ms -> 多任务 ==="
logcat -c
$VG double 307 60 200 2600 >/dev/null 2>&1; sleep 1.0
L "  app_log=$(dx 'double x' 3) app_switch=$(entry app_switch) top=$(top)"
startp

L ""
L "=== 6. 回归：X+LB 上一页 / X+RB 下一页（横向真实触摸手势）==="
: > "$HL"
$VG combo 307 310 300 2600 >/dev/null 2>&1; sleep 1.0
L "  X+LB: $(hl '^SWIPE' 4) | $(dx 'mix 4' 2)"
: > "$HL"
$VG combo 307 311 300 2600 >/dev/null 2>&1; sleep 1.0
L "  X+RB: $(hl '^SWIPE' 4) | $(dx 'mix 5' 2)"

L ""
L "=== 7. 回归：空闲隐藏原地隐形恢复（无修正移动）==="
startp
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.6
P1=$(clickxy)
HID0=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
sleep 9.5
HID1=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
logcat -c
$VG key 304 60 0 >/dev/null 2>&1; sleep 0.8
P2=$(clickxy)
L "  hide_before=$HID0 hide_after=$HID1 pos_before=[$P1] pos_after=[$P2] | $(dx 'pointer hidden|pointer shown|no correction' 4)"

L ""
L "=== 8. 回归：Y 单击 Home ==="
logcat -c
$VG key 308 80 0 >/dev/null 2>&1; sleep 1.0
L "  top=$(top) | $(dx 'single home|single.*fired' 3)"

L ""
L "=== 9. 回归：SELECT 真实下滑手势展开通知栏 ==="
cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
startp
: > "$HL"
$VG key 314 80 0 >/dev/null 2>&1; sleep 1.6
L "  focus=$(focus) shade=$(dumpsys window 2>/dev/null | grep -c 'mCurrentFocus=Window{.*NotificationShade') | $(hl 'NOTIF' 3)"
cmd statusbar collapse >/dev/null 2>&1
L "  after_collapse_focus=$(focus) top=$(top)"
L "DONE $(getprop ro.serialno)"

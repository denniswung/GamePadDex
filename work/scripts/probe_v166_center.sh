#!/system/bin/sh
# probe_v166_center.sh -- item2：L3 居中偶发失败（真实落点 / CENTER gain / 隐藏与 d-pad 导航模式）
# 用法：adb push work/scripts/probe_v166_center.sh /data/local/tmp/
#       adb shell su -c "sh /data/local/tmp/probe_v166_center.sh"
# 判定：|actual-(w/2,h/2)| <= 8px 合格
# 反推：helper pointer_goto 先 40 步有界推到 (0,0)，再按 gain 走 (w/2,h/2)
#       => actual_x = (w/2/gain)*G，因此 G = actual_x*gain/(w/2)
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
LOG=/data/local/tmp/v166_center.log

if pidof vgpad >/dev/null 2>&1; then echo "BUSY: vgpad already running"; exit 2; fi
: > "$LOG"
L(){ echo "$@" | tee -a "$LOG"; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
pin(){ settings put system accelerometer_rotation 0 >/dev/null 2>&1; settings put system user_rotation 1 >/dev/null 2>&1; sleep 1.5; }
startp(){ am force-stop $PAD; am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1; sleep 2.5; }
l3(){ $VG key 317 100 800 >/dev/null 2>&1; sleep 1.0; }
click(){ $VG key 304 80 0 >/dev/null 2>&1; sleep 0.5; }
stick(){ $VG stick "$1" "$2" "$3" 0 >/dev/null 2>&1; sleep 0.4; }
clickxy(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/click-down' | tail -1 | sed -n 's/.*click-down x=\([0-9]*\) y=\([0-9]*\).*/\1 \2/p'; }
sane(){ # 确认 padtest 在前台、通知栏已收起、点击能被记录（否则重启一次）
  cmd statusbar collapse >/dev/null 2>&1; sleep 0.5
  logcat -c; stick 0 -30000 250; click
  F=$(dumpsys window | grep -c 'mCurrentFocus=Window{.*padtest')
  if [ -z "$(clickxy)" ] || [ "$F" -lt 1 ]; then
    L "  [sane] no click-down / not focused (focus=$F) -> restart padtest"
    cmd statusbar collapse >/dev/null 2>&1
    startp; logcat -c; stick 0 -30000 250; click
    F=$(dumpsys window | grep -c 'mCurrentFocus=Window{.*padtest')
  fi
  L "  [sane] click-down=$(clickxy) padtest_focused=$F shade=$(dumpsys window | grep -c 'mCurrentFocus=Window{.*NotificationShade')"
}
report(){ # $1 label $2 W $3 H $4 gain
  A=$(clickxy); AX=${A% *}; AY=${A#* }
  CH=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed 's/^.*DexPad *: //')
  CL=$(grep -a '^CENTER' /data/adb/gpm/helper.log 2>/dev/null | tail -1)
  HID=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'pointer hidden')
  NAV=$(logcat -d -s DexPad 2>/dev/null | grep -ac 'native navigation')
  IM=$(awk -v ax="$AX" -v g="$4" -v w="$2" 'BEGIN{ if(ax==""||ax<=0||w<=0) print "n/a"; else printf "%.2f", ax*g/(w/2) }')
  L "  $1 actual=$A err=$(( ${AX:-0} - $2/2 )),$(( ${AY:-0} - $3/2 )) implied_G=$IM | $CH | $CL | hidden=$HID nav=$NAV"
}

wake; pin; sleep 1; startp
S=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p')
W=${S% *}; H=${S#* }; [ -z "$W" ] && W=2560; [ -z "$H" ] && H=1600
GAIN=$(grep -oE 'name="center_gain" value="[0-9]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | sed -n 's/.*value="\([0-9]*\)"/\1/p')
[ -z "$GAIN" ] && GAIN=216
G=$(awk -v g="$GAIN" 'BEGIN{printf "%.2f", g/100}')
l3; click   # 先做一次 L3 让引擎日志里出现 app size
S=$(logcat -d -s DexPad 2>/dev/null | grep -a 'cursor centered' | tail -1 | sed -n 's/.*cursor centered on \([0-9]*\)x\([0-9]*\).*/\1 \2/p')
W=${S% *}; H=${S#* }; [ -z "$W" ] && W=2560; [ -z "$H" ] && H=1600

L "=== 0. 屏幕与增益 ==="
L "  app_size=${W}x${H} (宽<高? $([ "$W" -lt "$H" ] && echo 是 || echo 否)) prefs_center_gain=$GAIN (=$G) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation) forced=$(settings get global display_size_forced)"
sane

L ""
L "=== T1/T2/T3: 不同起点连续三次 L3 ==="
logcat -c; l3; click; report "T1-from-prev-pos" "$W" "$H" "$G"
logcat -c; stick 0 -30000 500; l3; click; report "T2-after-left" "$W" "$H" "$G"
logcat -c; stick 1 30000 500; stick 0 30000 500; l3; click; report "T3-after-downright" "$W" "$H" "$G"

L ""
L "=== T4: 空闲隐藏（idle_hide_sec=8s）后再 L3 ==="
sleep 10
HID1=$(logcat -d -s DexPad | grep -ac 'pointer hidden')
logcat -c; l3; click; report "T4-after-idle-hide(10s)" "$W" "$H" "$G"
L "  hidden_before=$HID1 show_log=$(logcat -d -s DexPad | grep -a 'pointer shown' | tail -1 | sed 's/^.*DexPad *: //')"

L ""
L "=== T5: d-pad 导航（HAT 上 x2）后 L3：先看 A 是否还点鼠标 ==="
$VG hat 0 1 200 >/dev/null 2>&1; sleep 0.3
$VG hat 0 1 200 >/dev/null 2>&1; sleep 0.5
logcat -c; l3; click
A1=$(clickxy)
ENTER=$(logcat -d -s PadProbe | grep -c 'KEY/key-down KEYCODE_ENTER')
L "  after-dpad L3: mouse_click=[${A1:-none}] key_enter=$ENTER (A 走 DPAD_CENTER 而不是鼠标点击)"
L "  nav_log=$(logcat -d -s DexPad | grep -a -e navigation -e 'A -> DPAD_CENTER' | tail -3 | tr '\n' '|')"
# 推一下摇杆退出粘性导航后再点，才测得到落点
logcat -c; stick 4 13000 200; click; report "T5b-dpad-then-rstick" "$W" "$H" "$G"

L ""
L "=== T6: 空闲隐藏后再 L3（连续两次，复现"偶发"）==="
sleep 10
logcat -c; l3; stick 4 13000 200; click; report "T6a-idle" "$W" "$H" "$G"
logcat -c; l3; stick 4 13000 200; click; report "T6b-idle" "$W" "$H" "$G"

L ""
L "=== 对照：引擎估算（ptr move at）==="
L "  $(logcat -d -s DexPad | grep -a 'ptr move' | tail -3 | sed 's/^.*DexPad *: //' | tr '\n' '|')"
L "DONE $(getprop ro.serialno) rot=$(settings get system user_rotation) accel=$(settings get system accelerometer_rotation)"

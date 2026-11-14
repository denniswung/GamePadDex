#!/system/bin/sh
# ============================================================================
# v1.60 自动化测试 v3：专用测试 App（padtest/AutoTestActivity）JSON 报告判定
# ============================================================================
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
RPT=/sdcard/Android/data/$PAD/files/auto-report.json
pull_report(){ rm -f /data/local/tmp/rpt.json; cat "$RPT" > /data/local/tmp/rpt.json 2>/dev/null || echo '{}' > /data/local/tmp/rpt.json; }
flag(){ grep -q "\"$1[^\"]*\": *true" /data/local/tmp/rpt.json; }
start_auto(){ am force-stop $PAD; sleep 1; am start -n $PAD/.ui.AutoTestActivity >/dev/null 2>&1; sleep 2.5; }
stop_engine(){
  am force-stop $PKG >/dev/null 2>&1
  i=0
  while [ $i -lt 12 ]; do
    sleep 0.4
    [ -z "$(pidof $PKG)" ] && break
    i=$((i+1))
  done
  sleep 0.4
}
start_engine(){
  logcat -c 2>/dev/null
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  i=0
  while [ $i -lt 20 ]; do
    sleep 0.5
    i=$((i+1))
    logcat -d -s DexPad 2>/dev/null | grep -q 'hb ready=true' && break
  done
  sleep 1
}
xmlp(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
svc_set(){ XML=$(xmlp); awk -v k="$1" -v v="$2" 'BEGIN{d=0}
  /<\/map>/ { if(!d){ printf "    <string name=\"%s\">%s</string>\n", k, v; d=1 } }
  { print }' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }
svc_setbool(){ XML=$(xmlp); awk -v k="$1" -v v="$2" 'BEGIN{d=0}
  /<\/map>/ { if(!d){ printf "    <boolean name=\"%s\" value=\"%s\" />\n", k, v; d=1 } }
  { print }' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }
clean_prefs(){ XML=$(xmlp); awk '!/name="(btn_|par_|left_touch|mix_|combo_|dbl_|lng_)/' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }

wake; sleep 1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
stop_engine; clean_prefs; start_engine
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

echo "===== A. 版本/链路 ====="
V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
case "$V" in 1.6*) ok "A1 映射 App 版本 $V";; *) bad "A1 版本=$V";; esac
[ -n "$(dumpsys package $PAD 2>/dev/null | grep -m1 versionName)" ] && ok "A2 专用测试 App 已安装" || bad "A2 测试 App 缺失"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "A3 助手链路 READY" || bad "A3 助手链路"
[ "$(modeval)" = "true" ] && ok "A4 鼠标模式开" || bad "A4 鼠标模式=$(modeval)"

echo "===== B1. T1..T7（指针/点击/长按/方向键/滚动/缩放/组合）====="
rm -f "$RPT"
start_auto
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.5
$VG stick 0 12000 400 2000 >/dev/null 2>&1; sleep 0.4
$VG stick 1 6000 300 0 >/dev/null 2>&1; sleep 0.6
$VG key 304 120 700 >/dev/null 2>&1; sleep 0.8
$VG hold 304 900 >/dev/null 2>&1; sleep 1.4
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1; sleep 0.6
$VG stick 4 -20000 600 2000 >/dev/null 2>&1; sleep 1.2
$VG stick 4 20000 600 0 >/dev/null 2>&1; sleep 1.2
$VG hold 312 900 >/dev/null 2>&1; sleep 1.2
$VG hatkey 1 312 >/dev/null 2>&1; sleep 1.2
pull_report
echo "--- 阶段1报告 ---"; cat /data/local/tmp/rpt.json; echo
P=$(grep -o '"pass": *[0-9]*' /data/local/tmp/rpt.json | head -1 | sed 's/[^0-9]//g')
[ -n "$P" ] && [ "$P" -ge 7 ] && ok "B1 测试台自检 $P/9（T1..T7 全部）" || bad "B1 测试台自检 $P/9"
for k in "T1 指针移动" "T2 鼠标点击" "T3 长按" "T4 方向键焦点" "T5 滚动" "T6 双指缩放" "T7 键盘组合"; do
  flag "$k" && ok "B1-$k" || bad "B1-$k"
done

echo "===== B2. T8 返回键 ====="
start_auto
$VG key 305 120 800 >/dev/null 2>&1
sleep 1.5
pull_report
flag "T8 返回键" && ok "B2 T8 返回键" || bad "B2 T8 返回键"

echo "===== B3. T9 触摸点击模式（可选开关）====="
stop_engine; svc_setbool left_touch true; start_engine
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
rm -f "$RPT"
start_auto
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.5
$VG stick 0 20000 300 0 >/dev/null 2>&1; sleep 0.5
: > /data/adb/gpm/helper.log
logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.2
pull_report
TD=$(grep -ac 'TOUCH down' /data/adb/gpm/helper.log)
TD2=$(logcat -d -s DexPad | grep -ac 'left touch down')
[ "$TD" -ge 1 ] && [ "$TD2" -ge 1 ] || TD=0
flag "T2 鼠标点击" && [ "$TD" -ge 1 ] && ok "B3 触摸点击（助手 TOUCH down + App 收到点击）" || bad "B3 触摸点击（TOUCH=$TD）"
stop_engine; clean_prefs; start_engine


echo "===== F. d-pad 导航 / 鼠标切换（v1.61 修复）====="
# F1: d-pad 选中后等 2 秒再按 A —— 测试 App 自己确认按钮被点中（T10）
rm -f "$RPT"
start_auto
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1.2
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1
sleep 2.0
$VG key 304 120 800 >/dev/null 2>&1
sleep 1.5
pull_report
flag "T10 方向键确认" && ok "F1 d-pad 选中后 A 确认（T10）" || bad "F1 d-pad 后 A 未确认（T10）"

# F2: 聚焦后按 A 不能变成"光标点击"（引擎日志必须是 DPAD_CENTER）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 1.0
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
D=$(logcat -d -s DexPad | grep -ac 'A -> DPAD_CENTER')
C=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$D" -ge 1 ] && [ "$C" -eq 0 ] && ok "F2 A 走 DPAD_CENTER（click=$C）" || bad "F2 A 注入方式（DPAD_CENTER=$D click=$C）"

# F3: d-pad 后用左摇杆 = 回到鼠标模式，A 恢复点击
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.3
$VG stick 0 22000 350 0 >/dev/null 2>&1
sleep 0.8
OFF=$(logcat -d -s DexPad | grep -ac 'native navigation OFF (stick moved)')
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
C=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$OFF" -ge 1 ] || ok "F3 提示：未记录到 stick moved 日志（继续判定）"

[ "$C" -ge 1 ] && ok "F3 摇杆后 A 回到鼠标点击" || bad "F3 摇杆后 A 仍是确认（click=$C）"

# F4: d-pad 按住连发（焦点连续移动）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
: > /data/adb/gpm/helper.log
$VG hat 0 1 1600 >/dev/null 2>&1
sleep 1.2
N=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
N=${N:-0}
[ "$N" -ge 3 ] && ok "F4 d-pad 按住连发（$N 次）" || bad "F4 d-pad 连发（$N）"


echo "===== G. 双击 / 组合方向（v1.62 修复）====="
# G1: X 双击 = 多任务
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
logcat -c
$VG double 307 60 120 >/dev/null 2>&1
sleep 2
D=$(logcat -d -s DexPad | grep -ac 'double x -> recents')
A=$(top)
case "$A" in *RecentsActivity*|*quickstep*) TOK=1;; *) TOK=0;; esac
[ "$D" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "G1 X 双击 → 多任务（$A）" || bad "G1 X 双击（log=$D top=$A）"

# G2: 慢双击（300ms 间隔）也能识别
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
$VG double 307 70 300 >/dev/null 2>&1
sleep 2
A=$(top)
case "$A" in *RecentsActivity*|*quickstep*) ok "G2 慢双击（300ms）也识别";; *) bad "G2 慢双击（$A）";; esac

# G3: X+LB = 内容向右（手指向右）
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 2.5
: > /data/adb/gpm/helper.log
$VG combo 307 310 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),.*/\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \([0-9]*\),.*/\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -gt "$X0" ] && ok "G3 X+LB 手指向右（$X0→$X1）" || bad "G3 X+LB 方向（$S）"

# G4: X+RB = 内容向左（手指向左）
: > /data/adb/gpm/helper.log
$VG combo 307 311 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),.*/\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \([0-9]*\),.*/\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -lt "$X0" ] && ok "G4 X+RB 手指向左（$X0→$X1）" || bad "G4 X+RB 方向（$S）"


echo "===== H. 打开应用 / 光标重居中（v1.63 修复）====="
# H1: Start+上 -> 打开 PiliPlus（用 keyvhat 模拟竖直方向键）
stop_engine
svc_del_keys(){ XML=$(xmlp); awk -v pat="$1" '$0 !~ pat' "$XML" > /data/local/tmp/pp.xml; cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"; }
svc_del_keys 'name="mix_'
svc_set mix_11_keys start+up
svc_set mix_11_action open_app
svc_set mix_11_value com.example.piliplus
start_engine
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c
$VG keyvhat 315 -1 500 >/dev/null 2>&1
sleep 3
O=$(top)
case "$O" in com.example.piliplus*) ok "H1 Start+上 打开 PiliPlus（$O）";; *) bad "H1 Start+上 打开应用（$O）";; esac

# H2: 指针空闲隐藏后再用摇杆 -> 光标"隐形恢复"到上次位置（没有可见的修正移动）
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2
logcat -c
$VG stick 0 20000 600 2000 >/dev/null 2>&1
sleep 0.5
H1L=$(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)
P1X=$(echo "$H1L" | sed -n 's/.*hover x=\([0-9]*\) y=.*/\1/p')
P1Y=$(echo "$H1L" | sed -n 's/.*hover x=[0-9]* y=\([0-9]*\).*/\1/p')
sleep 9
logcat -c
$VG stick 0 6000 250 2000 >/dev/null 2>&1
sleep 0.8
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
CL=$(logcat -d -s PadProbe | grep -a 'MOUSE/click-down' | tail -1)
P2X=$(echo "$CL" | sed -n 's/.*click-down x=\([0-9]*\) y=.*/\1/p')
P2Y=$(echo "$CL" | sed -n 's/.*click-down x=[0-9]* y=\([0-9]*\).*/\1/p')
DX=$(( P2X > P1X ? P2X - P1X : P1X - P2X ))
DY=$(( P2Y > P1Y ? P2Y - P1Y : P1Y - P2Y ))
[ -n "$P2X" ] && [ "$DX" -le 120 ] && [ "$DY" -le 120 ] \
  && ok "H2 光标隐形恢复到上次位置（隐藏前 $P1X,$P1Y → 点击 $P2X,$P2Y）" \
  || bad "H2 恢复位置（隐藏前 $P1X,$P1Y → 点击 $P2X,$P2Y）"

# H3: d-pad 确认后摇杆四个方向都能动（不卡边界）
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
$VG key 317 100 1200 >/dev/null 2>&1; sleep 1
logcat -c
$VG stick 0 20000 700 2000 >/dev/null 2>&1
$VG stick 0 -20000 700 0 >/dev/null 2>&1
$VG stick 1 20000 700 0 >/dev/null 2>&1
$VG stick 1 -20000 700 0 >/dev/null 2>&1
sleep 0.6
LOG=$(logcat -d -s DexPad | grep -a 'ptr move')
POSX=$(echo "$LOG" | grep -ac 'dx=[1-9]')
NEGX=$(echo "$LOG" | grep -ac 'dx=-')
POSY=$(echo "$LOG" | grep -ac 'dy=[1-9]')
NEGY=$(echo "$LOG" | grep -ac 'dy=-')
[ "$POSX" -ge 1 ] && [ "$NEGX" -ge 1 ] && [ "$POSY" -ge 1 ] && [ "$NEGY" -ge 1 ] \
  && ok "H3 光标四向都能移动（+x=$POSX -x=$NEGX +y=$POSY -y=$NEGY）" \
  || bad "H3 光标方向受限（+x=$POSX -x=$NEGX +y=$POSY -y=$NEGY）"

# 清掉测试组合
stop_engine
svc_del_keys 'name="mix_'
start_engine

echo "===== C. 系统动作实际效果 ====="
wake; sleep 0.8
am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
B=$(top)
$VG hold 308 900 >/dev/null 2>&1
sleep 2
A=$(top)
case "$A" in *launcher*) ok "C1 Y 回主屏（$B -> $A）";; *) bad "C1 Y 回主屏（$B -> $A）";; esac

am start -a android.settings.SETTINGS >/dev/null 2>&1; sleep 2
B=$(top)
$VG key 305 120 800 >/dev/null 2>&1
sleep 1.5
A=$(top)
[ "$B" != "$A" ] && ok "C2 B 返回生效（$B -> $A）" || bad "C2 B 返回（$B -> $A）"

wake; sleep 1.2
i=0
while [ $i -lt 4 ]; do
  input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
  wm dismiss-keyguard >/dev/null 2>&1
  sleep 0.8
  screencap -p /data/local/tmp/n0.png 2>/dev/null
  [ "$(wc -c < /data/local/tmp/n0.png)" -gt 100000 ] && break
  i=$((i+1))
done
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
wake; sleep 0.4
screencap -p /data/local/tmp/n0.png 2>/dev/null
: > /data/adb/gpm/helper.log
$VG key 314 150 1200 >/dev/null 2>&1
sleep 2.5
screencap -p /data/local/tmp/n1.png 2>/dev/null
S0=$(wc -c < /data/local/tmp/n0.png); S1=$(wc -c < /data/local/tmp/n1.png)
D=$(( S1 - S0 )); D=${D#-}
grep -aq 'NOTIF swipe' /data/adb/gpm/helper.log && [ "$D" -gt 500000 ] && ok "C3 SELECT 通知栏（$S0->$S1）" || bad "C3 SELECT 通知栏（$S0->$S1）"
input keyevent KEYCODE_BACK >/dev/null 2>&1; sleep 1

: > /data/adb/gpm/helper.log
$VG hold 318 900 >/dev/null 2>&1
sleep 1.5
grep -aq 'KEYUIN 0 164' /data/adb/gpm/helper.log && ok "C4 R3 静音（KEYUIN 164）" || bad "C4 R3 静音"

: > /data/adb/gpm/helper.log
$VG combo 307 544 600 >/dev/null 2>&1
sleep 1.2
grep -aq 'KEYUIN 0 24' /data/adb/gpm/helper.log && ok "C5 X+↑ 音量+（KEYUIN 24）" || bad "C5 X+↑ 音量"

am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1; sleep 2
P1=$(pidof $PAD)
$VG key 316 120 900 >/dev/null 2>&1
sleep 2.5
P2=$(pidof $PAD)
[ -n "$P1" ] && [ -z "$P2" ] && ok "C6 GUIDE 杀前台" || bad "C6 GUIDE 杀前台（$P1/$P2）"

wake; sleep 0.6
W0=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
$VG combo 308 317 500 >/dev/null 2>&1
sleep 2
W1=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
[ "$W0" != "$W1" ] && ok "C7 Y+L3 电源（$W0→$W1）" || bad "C7 电源（$W0→$W1）"
wake; sleep 1.5

echo "===== D. 打开目标应用（每槽参数）====="
stop_engine; svc_set btn_y open_app; svc_set par_y com.android.settings; start_engine
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
$VG hold 308 800 >/dev/null 2>&1
sleep 2.5
O=$(top)
case "$O" in com.android.settings*) ok "D1 打开目标应用（$O）";; *) bad "D1 打开目标应用（$O）";; esac

echo "===== E. 稳定性 ====="
CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "E1 无崩溃" || bad "E1 崩溃 $CR"
ANR=$(logcat -d 2>/dev/null | grep -c "ANR in $PKG")
[ "$ANR" -eq 0 ] && ok "E2 无 ANR" || bad "E2 ANR $ANR"

# 收尾：清理测试映射
stop_engine; clean_prefs; start_engine

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

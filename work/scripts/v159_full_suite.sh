#!/system/bin/sh
# ============================================================================
# GamePadDex v1.59 全量测试套件（Release 构建专用，不依赖调试广播）
# 结果：PASS/FAIL 逐条打印；证据同时写到 /data/local/tmp/suite.log
# ============================================================================
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
LOG=/data/local/tmp/suite.log
: > $LOG

ok(){ echo "PASS  $*"; PASS=$((PASS+1)); echo "PASS  $*" >> $LOG; }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); echo "FAIL  $*" >> $LOG; }
ev(){ echo "        $*"; echo "        $*" >> $LOG; }

modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
xmlpath(){ ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
hl(){ tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hc(){ wc -l < /data/adb/gpm/helper.log; }
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }

# ---------------------------------------------------------------- 环境准备
wake; sleep 1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

# ================================================================ A 版本/链路
echo "===== A. 版本与链路 ====="
V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
VC=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionCode | sed 's/[^0-9]//g')
[ "$V" = "1.59" ] && ok "A1 应用版本 $V" || bad "A1 应用版本=$V"
[ "$VC" = "61" ] && ok "A2 versionCode $VC" || bad "A2 versionCode=$VC"
MH=$(sha256sum /data/adb/gpm/gpminput 2>/dev/null | cut -d' ' -f1)
MODH=$(sha256sum /data/adb/modules/gpm_dex/gpminput 2>/dev/null | cut -d' ' -f1)
[ "$MH" = "8f9930f0f5db5a42b14fe4c78726fabb3a1f5e75eb21cfdbfffa2fd3b47bf9fc" ] && ok "A3 运行助手=构建产物" || bad "A3 助手 hash=$MH"
[ "$MH" = "$MODH" ] && ok "A4 模块内助手一致" || bad "A4 模块助手 hash=$MODH"
grep -q 'version=v1.59' /data/adb/modules/gpm_dex/module.prop 2>/dev/null && ok "A5 模块版本 v1.59" || bad "A5 模块版本"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "A6 助手链路 READY" || bad "A6 助手链路"
grep -aq 'SELFTEST end' /data/adb/gpm/helper.log && ok "A7 助手自检完成" || bad "A7 自检"
# 单实例：再起一个应当立刻退出
BEFORE=$(ps -A -o NAME | grep -c gpminput)
/data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/tmp/h2.log 2>&1
sleep 1
AFTER=$(ps -A -o NAME | grep -c gpminput)
grep -q 'another helper holds the lock' /tmp/h2.log && ok "A8 单实例锁生效" || bad "A8 单实例锁（before=$BEFORE after=$AFTER）"

# ================================================================ B 光标
echo "===== B. 光标 ====="
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
logcat -c
$VG stick 0 15000 400 2000 >/dev/null 2>&1
sleep 0.4
N=$(logcat -d -s DexPad | grep -ac 'ptr move')
[ "$N" -ge 3 ] && ok "B1 左摇杆移动光标（$N 帧）" || bad "B1 左摇杆移动（$N）"

# 死区：小推不动
logcat -c
$VG stick 0 2000 300 0 >/dev/null 2>&1
sleep 0.4
N=$(logcat -d -s DexPad | grep -ac 'ptr move')
[ "$N" -eq 0 ] && ok "B2 死区内不移动（大量小推=0 帧）" || bad "B2 死区（$N 帧）"

# 松手不滑行
$VG stick 0 20000 400 0 >/dev/null 2>&1
sleep 0.35; logcat -c; sleep 0.9
N=$(logcat -d -s DexPad | grep -ac 'ptr move')
[ "$N" -eq 0 ] && ok "B3 松手不滑行" || bad "B3 松手滑行（$N 帧）"

# 边缘不越界
logcat -c
$VG stick 0 -20000 3000 2000 >/dev/null 2>&1
$VG stick 1 -20000 3000 0 >/dev/null 2>&1
sleep 0.5
P=$(logcat -d -s DexPad | grep -a 'ptr move' | tail -1)
X=$(echo "$P" | sed -n 's/.*at \([0-9]*\),.*/\1/p')
Y=$(echo "$P" | sed -n 's/.*,\([0-9]*\)$/\1/p')
if [ -n "$X" ] && [ -n "$Y" ] && [ "$X" -ge 0 ] && [ "$X" -le 2560 ] && [ "$Y" -ge 0 ] && [ "$Y" -le 1600 ]; then
  ok "B4 长推后光标在屏内（$X,$Y）"
else
  bad "B4 光标越界（$P）"
fi

# 精准模式：X+左摇杆 速度应更慢
$VG key 317 80 300 >/dev/null 2>&1      # 先居中，便于比较
sleep 0.8
logcat -c
$VG stick 0 15000 300 0 >/dev/null 2>&1
sleep 0.3
FAST=$(logcat -d -s DexPad | grep -ao 'dx=[0-9-]*' | sed 's/dx=//' | awk '{s+=$1} END{print s+0}')
logcat -c
( $VG hold 307 1200 >/dev/null 2>&1 ) &
sleep 0.25
$VG stick 0 15000 300 0 >/dev/null 2>&1
sleep 1.1
SLOW=$(logcat -d -s DexPad | grep -ao 'dx=[0-9-]*' | sed 's/dx=//' | awk '{s+=$1} END{print s+0}')
FAST=${FAST#-}; SLOW=${SLOW#-}
if [ "$FAST" -gt 0 ] && [ "$SLOW" -gt 0 ] && [ "$SLOW" -lt "$FAST" ]; then
  ok "B5 精准模式更慢（普通=$FAST 精准=$SLOW）"
else
  bad "B5 精准模式（普通=$FAST 精准=$SLOW）"
fi

# L3 居中
logcat -c; : > /data/adb/gpm/helper.log
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.5
grep -aq 'CENTER(steps+gain' /data/adb/gpm/helper.log && ok "B6 L3 居中命令执行" || bad "B6 L3 居中命令"

# ================================================================ C 点击/按键
echo "===== C. 点击与按键 ====="
logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1
B=$(logcat -d -s DexPad | grep -ac 'left button down'); T=$(logcat -d -s DexPad | grep -ac 'left touch down')
[ "$B" -ge 1 ] && [ "$T" -eq 0 ] && ok "C1 A=鼠标左键（非触摸）" || bad "C1 A 注入 button=$B touch=$T"

logcat -c
$VG hold 304 800 >/dev/null 2>&1
sleep 1.4
B=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$B" -ge 1 ] && ok "C2 A 长按（按住 800ms）" || bad "C2 A 长按（$B）"

: > /data/adb/gpm/helper.log; logcat -c
$VG key 305 120 800 >/dev/null 2>&1
sleep 1
grep -aq 'KEY .* 158 ' /data/adb/gpm/helper.log || logcat -d -s DexPad | grep -aq 'back on display' && ok "C3 B=返回" || bad "C3 B=返回"

: > /data/adb/gpm/helper.log
$VG key 308 120 800 >/dev/null 2>&1
sleep 1
grep -aq 'KEYON 0 3' /data/adb/gpm/helper.log && ok "C4 Y=主屏" || bad "C4 Y=主屏"

: > /data/adb/gpm/helper.log
$VG key 318 120 800 >/dev/null 2>&1
sleep 1
grep -aq 'KEYON 0 164' /data/adb/gpm/helper.log || grep -aq ' 164 ' /data/adb/gpm/helper.log && ok "C5 R3=静音" || bad "C5 R3=静音"

# GUIDE 杀前台
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
P1=$(pidof com.dennis.padtest)
$VG key 315 120 800 >/dev/null 2>&1      # GUIDE(314)=BTN_SELECT? 用 315=BTN_START 先测 START
sleep 1

# 重新用正确 GUIDE 码：BTN_MODE=316
$VG key 316 120 800 >/dev/null 2>&1
sleep 2.5
P2=$(pidof com.dennis.padtest)
[ -n "$P1" ] && [ -z "$P2" ] && ok "C6 GUIDE 短按杀前台（$P1→已死）" || bad "C6 GUIDE 杀前台（P1=$P1 P2=$P2）"

# ================================================================ D 滚动/滑动
echo "===== D. 滚动与滑动 ====="
am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3

: > /data/adb/gpm/helper.log
$VG stick 4 -20000 700 2000 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
Y0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -gt "$Y0" ] && [ "$Y0" -gt 300 ] && ok "D1 右摇杆向上=中屏向下拖（$Y0→$Y1）" || bad "D1 右摇杆向上（$S）"

: > /data/adb/gpm/helper.log
$VG stick 4 20000 700 0 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
Y0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "D2 右摇杆向下=反向拖（$Y0→$Y1）" || bad "D2 右摇杆向下（$S）"

: > /data/adb/gpm/helper.log
$VG stick 3 -20000 700 0 >/dev/null 2>&1      # ABS_RX (3) = 右摇杆 X
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),.*/\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \([0-9]*\),.*/\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X0" -ne "$X1" ] && ok "D3 右摇杆左右=横向滑动（$X0→$X1）" || bad "D3 横向滑动（$S）"

: > /data/adb/gpm/helper.log
$VG key 311 120 800 >/dev/null 2>&1      # RB
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
Y0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "D4 RB=手指上滑（$Y0→$Y1）" || bad "D4 RB（$S）"

: > /data/adb/gpm/helper.log
$VG key 310 120 800 >/dev/null 2>&1      # LB
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
Y0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -gt "$Y0" ] && ok "D5 LB=手指下滑（$Y0→$Y1）" || bad "D5 LB（$S）"

PMAX=$(grep -a 'prep=' /data/adb/gpm/helper.log | sed -n 's/.*prep=\([0-9]*\)us/\1/p' | sort -n | tail -1)
[ -n "$PMAX" ] && [ "$PMAX" -lt 20000 ] && ok "D6 滑动准备耗时 ${PMAX}us（<20ms）" || bad "D6 滑动耗时 ${PMAX}us"

# ================================================================ E 组合键
echo "===== E. 组合键 ====="
combo_test(){  # $1=k1 $2=k2 $3=grep-pattern $4=描述
  : > /data/adb/gpm/helper.log
  $VG combo "$1" "$2" 600 >/dev/null 2>&1
  sleep 1.2
  if grep -aq "$3" /data/adb/gpm/helper.log || logcat -d -s DexPad | grep -aq "$3"; then ok "$4"; else bad "$4（无匹配 $3）"; fi
}
combo_test 307 544 'VOLUME\|KCOMBO 0 1\| 24 ' "E1 X+↑ 音量+"
combo_test 307 545 ' 25 ' "E2 X+↓ 音量-"
combo_test 307 546 ' 165 ' "E3 X+← 上一曲"
combo_test 307 547 ' 163 ' "E4 X+→ 下一曲"

: > /data/adb/gpm/helper.log
$VG combo 307 310 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),.*/\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \([0-9]*\),.*/\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -lt "$X0" ] && ok "E5 X+LB 左滑（$X0→$X1）" || bad "E5 X+LB 左滑（$S）"

: > /data/adb/gpm/helper.log
$VG combo 307 311 700 >/dev/null 2>&1
sleep 1.2
S=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
X0=$(echo "$S" | sed -n 's/.*SWIPE [0-9]* \([0-9]*\),.*/\1/p')
X1=$(echo "$S" | sed -n 's/.* -> \([0-9]*\),.*/\1/p')
[ -n "$X0" ] && [ -n "$X1" ] && [ "$X1" -gt "$X0" ] && ok "E6 X+RB 右滑（$X0→$X1）" || bad "E6 X+RB 右滑（$S）"

wake; sleep 0.5
W0=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
: > /data/adb/gpm/helper.log
$VG combo 308 317 500 >/dev/null 2>&1
sleep 2
W1=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
[ "$W0" != "$W1" ] && ok "E7 Y+L3 电源（$W0→$W1）" || bad "E7 Y+L3 电源（$W0→$W1）"
wake; sleep 1.5

# ================================================================ F 模式
echo "===== F. 模式与状态 ====="
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
logcat -c
$VG key 167 120 800 >/dev/null 2>&1     # SHARE 关
sleep 1.2
[ "$(modeval)" = "false" ] && ok "F1 SHARE 关闭鼠标模式" || bad "F1 关闭模式（$(modeval)）"
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
B=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$B" -eq 0 ] && ok "F2 模式关时 A 不动作" || bad "F2 模式关仍动作（$B）"
$VG key 167 120 800 >/dev/null 2>&1
sleep 1.2
[ "$(modeval)" = "true" ] && ok "F3 SHARE 重新开启" || bad "F3 重新开启（$(modeval)）"
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
B=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$B" -ge 1 ] && ok "F4 模式恢复后 A 正常" || bad "F4 恢复后 A（$B）"

# 空闲隐藏指针
$VG stick 0 8000 300 2000 >/dev/null 2>&1
sleep 0.5
M0=$(grep -ac 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null)
sleep 9
M1=$(grep -ac 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null)
$VG stick 0 8000 300 0 >/dev/null 2>&1
sleep 1.2
M2=$(grep -ac 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null)
[ "$M1" -eq 0 ] && [ "$M2" -ge 1 ] && ok "F5 空闲隐藏指针并恢复（$M0→$M1→$M2）" || bad "F5 指针隐藏（$M0→$M1→$M2）"

# 断线重连
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >>/data/adb/gpm/helper.log 2>&1 &
sleep 3
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1.2
B=$(logcat -d -s DexPad | grep -ac 'left button down')
[ "$B" -ge 1 ] && ok "F6 助手重启后自动重连并可用" || bad "F6 重连后点击（$B）"

# ================================================================ G d-pad
echo "===== G. 方向键 ====="
: > /data/adb/gpm/helper.log
$VG hat 0 1 300 >/dev/null 2>&1
sleep 1
N=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
[ "$N" -ge 1 ] && ok "G1 方向键发出（$N 次）" || bad "G1 方向键（$N）"

: > /data/adb/gpm/helper.log
$VG hat 0 1 1600 >/dev/null 2>&1
sleep 2.2
N=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
[ "$N" -ge 3 ] && ok "G2 按住连发（1.6s 内 $N 次）" || bad "G2 连发（$N）"

logcat -c
$VG hat 0 1 300 >/dev/null 2>&1
sleep 0.5
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
logcat -d -s DexPad | grep -aq 'DPAD_CENTER' && ok "G3 d-pad 模式 A=确认焦点" || bad "G3 d-pad 模式 A 确认"

# ================================================================ H 缩放
echo "===== H. 缩放 ====="
: > /data/adb/gpm/helper.log; logcat -c
$VG hold 312 800 >/dev/null 2>&1
sleep 1.2
S=$(grep -ac 'PINCH start dir=-1' /data/adb/gpm/helper.log); E=$(logcat -d -s DexPad | grep -ac 'pinch zoom out')
[ "$S" -ge 1 ] && [ "$E" -ge 1 ] && ok "H1 LT=双指缩小" || bad "H1 LT（pinch=$S engine=$E）"

: > /data/adb/gpm/helper.log; logcat -c
$VG hold 313 800 >/dev/null 2>&1
sleep 1.2
S=$(grep -ac 'PINCH start dir=1' /data/adb/gpm/helper.log); E=$(logcat -d -s DexPad | grep -ac 'pinch zoom in')
[ "$S" -ge 1 ] && [ "$E" -ge 1 ] && ok "H2 RT=双指放大" || bad "H2 RT（pinch=$S engine=$E）"

: > /data/adb/gpm/helper.log; logcat -c
($VG hat 1 -1 3000 >/dev/null 2>&1) &
sleep 0.4
$VG key 312 120 700 >/dev/null 2>&1
sleep 1.2
P=$(grep -ac 'PINCH' /data/adb/gpm/helper.log); K=$(grep -ac 'KCOMBO' /data/adb/gpm/helper.log)
[ "$K" -ge 1 ] && [ "$P" -eq 0 ] && ok "H3 d-pad 模式 LT=Ctrl+-（无手势）" || bad "H3 d-pad 缩放（KCOMBO=$K PINCH=$P）"
wait 2>/dev/null

# ================================================================ I 打开应用
echo "===== I. 打开目标应用 ====="
XML=$(xmlpath)
am force-stop $PKG; sleep 1
awk 'BEGIN{done=0}
/<\/map>/ { if(!done){ print "    <string name=\"btn_y\">open_app</string>"; print "    <string name=\"par_y\">com.android.settings</string>"; print "    <string name=\"mix_0_action\">open_app</string>"; print "    <string name=\"mix_0_keys\">x+r3</string>"; print "    <string name=\"mix_0_value\">com.android.settings</string>"; done=1 } }
{ print }' "$XML" > /data/local/tmp/p.xml
cat /data/local/tmp/p.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c
$VG hold 308 800 >/dev/null 2>&1
sleep 2.5
O=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
TOP=$(top)
case "$TOP" in com.android.settings*) TOK=1;; *) TOK=0;; esac
[ "$O" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "I1 每槽参数打开应用（$TOP）" || bad "I1 打开应用（O=$O top=$TOP）"

input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c
$VG combo 307 318 700 >/dev/null 2>&1
sleep 2.5
O2=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
TOP2=$(top)
case "$TOP2" in com.android.settings*) TOK2=1;; *) TOK2=0;; esac
[ "$O2" -ge 1 ] && [ "$TOK2" -eq 1 ] && ok "I2 组合槽打开应用（$TOP2）" || bad "I2 组合槽打开应用（O=$O2 top=$TOP2）"

# ================================================================ J 稳定性
echo "===== J. 稳定性 ====="
CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "J1 无崩溃" || bad "J1 崩溃 $CR"
ANR=$(logcat -d 2>/dev/null | grep -c "ANR in $PKG")
[ "$ANR" -eq 0 ] && ok "J2 无 ANR" || bad "J2 ANR $ANR"
SZ=$(wc -c < /data/adb/gpm/helper.log)
[ "$SZ" -lt 3000000 ] && ok "J3 助手日志体积正常（$((SZ/1024))KB）" || bad "J3 日志体积 $((SZ/1024))KB"
ERR=$(grep -ac 'ERR ' /data/adb/gpm/helper.log)
[ "$ERR" -eq 0 ] && ok "J4 助手无错误日志" || bad "J4 助手错误日志 $ERR 条"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
echo "PASS=$PASS FAIL=$FAIL" >> $LOG

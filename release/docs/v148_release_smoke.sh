#!/system/bin/sh
# v1.48 Release 冒烟：不含广播类用例（Release 没有 DebugReceiver）
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
dlog(){ logcat -d -s DexPad 2>/dev/null; }
hl(){ tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hc(){ wc -l < /data/adb/gpm/helper.log; }

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

# 版本
V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.48" ] && ok "安装版本 $V" || bad "版本 = $V"

# 链路
dlog | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"
LAST=$(hl 0 | grep -n 'SELFTEST begin' | tail -1 | cut -d: -f1)
CAPS=$(hl 0 | tail -n +${LAST:-1} | grep -c 'CAP ')
[ "$CAPS" -ge 9 ] && ok "自检 $CAPS 项" || bad "自检 $CAPS"

am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

# Y = Home（不锁屏）
logcat -c; L=$(hc)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.2
H=$(hl "$L" | grep -c 'KEYON 0 3'); P=$(hl "$L" | grep -c 'POWER')
[ "$H" -ge 1 ] && [ "$P" -eq 0 ] && ok "Y -> Home（无电源）" || bad "Y home=$H power=$P"

# 光标不滑行
logcat -c
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.35; logcat -c; sleep 0.9
N=$(dlog | grep -c 'ptr move')
[ "$N" -eq 0 ] && ok "松手不滑行" || bad "松手仍滑 ($N)"

# LB/RB 方向（应用内）
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 1.4
logcat -c; L=$(hc); $VG key 311 400 2000 >/dev/null 2>&1; sleep 1.0
S1=$(hl "$L" | grep -m1 'SWIPE'); echo "      RB: $S1"
Y0=$(echo "$S1" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y1=$(echo "$S1" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "RB -> 手指上滑/内容下滑 ($Y0->$Y1)" || bad "RB 方向 ($Y0->$Y1)"
logcat -c; L=$(hc); $VG key 310 400 0 >/dev/null 2>&1; sleep 1.0
S2=$(hl "$L" | grep -m1 'SWIPE'); echo "      LB: $S2"
Y2=$(echo "$S2" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
Y3=$(echo "$S2" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y2" ] && [ -n "$Y3" ] && [ "$Y3" -gt "$Y2" ] && ok "LB -> 手指下滑/内容上滚 ($Y2->$Y3)" || bad "LB 方向 ($Y2->$Y3)"

# 桌面：LB/RB 转方向键
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; L=$(hc); $VG key 310 400 2000 >/dev/null 2>&1; sleep 1.0
SW=$(hl "$L" | grep -c 'SWIPE'); AR=$(dlog | grep -c 'launcher foreground')
[ "$SW" -eq 0 ] && [ "$AR" -ge 1 ] && ok "桌面 LB -> 方向键（不拉通知栏）" || bad "桌面 LB swipe=$SW launcher=$AR"

# 无崩溃
CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

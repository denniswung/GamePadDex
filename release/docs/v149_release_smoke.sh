#!/system/bin/sh
# v1.49 Release 冒烟：在 v1.48 基础上加「空闲隐藏指针」
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
dlog(){ logcat -d -s DexPad 2>/dev/null; }
hl(){ tail -n +$(( ${1:-0} + 1 )) /data/adb/gpm/helper.log 2>/dev/null; }
hc(){ wc -l < /data/adb/gpm/helper.log; }
kdev(){ grep -c 'Gamepad Mouse Pointer' /proc/bus/input/devices 2>/dev/null; }

ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.49" ] && ok "版本 $V" || bad "版本 = $V"
dlog | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"

am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

# Y -> Home 且不锁屏
logcat -c; L=$(hc)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.2
H=$(hl "$L" | grep -c 'KEYON 0 3'); P=$(hl "$L" | grep -c 'POWER')
[ "$H" -ge 1 ] && [ "$P" -eq 0 ] && ok "Y -> Home（无电源）" || bad "Y home=$H power=$P"

# 松手不滑行
logcat -c
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.35; logcat -c; sleep 0.9
N=$(dlog | grep -c 'ptr move')
[ "$N" -eq 0 ] && ok "松手不滑行" || bad "松手仍滑 ($N)"

# 空闲自动隐藏指针（8s）：内核里鼠标设备应消失
$VG stick 0 20000 300 2000 >/dev/null 2>&1   # 先让鼠标存在
sleep 1
K0=$(kdev)
sleep 9
K1=$(kdev)
[ "$K0" -ge 1 ] && [ "$K1" -eq 0 ] && ok "空闲隐藏指针（设备 $K0 -> $K1）" || bad "空闲隐藏 (K0=$K0 K1=$K1)"
dlog | grep -q 'pointer hidden' && ok "隐藏日志" || bad "隐藏日志"

# 摇杆一动恢复
$VG stick 0 20000 300 0 >/dev/null 2>&1
sleep 1
K2=$(kdev)
[ "$K2" -ge 1 ] && ok "摇杆恢复指针（设备=$K2）" || bad "恢复指针 (K2=$K2)"

# LB/RB 方向 + 桌面转方向键
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1; sleep 1.4
logcat -c; L=$(hc); $VG key 311 400 2000 >/dev/null 2>&1; sleep 1.0
S1=$(hl "$L" | grep -m1 'SWIPE'); Y0=$(echo "$S1" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p'); Y1=$(echo "$S1" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
[ -n "$Y0" ] && [ -n "$Y1" ] && [ "$Y1" -lt "$Y0" ] && ok "RB -> 上滑/内容下滑 ($Y0->$Y1)" || bad "RB 方向 ($Y0->$Y1)"
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; L=$(hc); $VG key 310 400 2000 >/dev/null 2>&1; sleep 1.0
SW=$(hl "$L" | grep -c 'SWIPE'); AR=$(dlog | grep -c 'launcher foreground')
[ "$SW" -eq 0 ] && [ "$AR" -ge 1 ] && ok "桌面 LB -> 方向键" || bad "桌面 LB swipe=$SW launcher=$AR"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

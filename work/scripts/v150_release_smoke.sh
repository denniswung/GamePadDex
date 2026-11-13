#!/system/bin/sh
# v1.50 Release 冒烟：一次性居中（绝对指针）
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

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.50" ] && ok "版本 $V" || bad "版本 = $V"
dlog | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"

# 绝对指针设备存在
grep -q 'Gamepad Absolute Pointer' /proc/bus/input/devices && ok "绝对指针设备已创建" || bad "绝对指针设备缺失"

am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 1.5

# 一次性居中：连按 3 次，位置必须完全一致，且只用 abs 路径
P1=""; SAME=1; ABSN=0; LIN=0
for i in 1 2 3; do
    $VG stick 0 20000 250 0 >/dev/null 2>&1
    sleep 0.2
    $VG key 317 100 1200 >/dev/null 2>&1
    sleep 0.9
    H=$(dumpsys input 2>/dev/null | grep -m1 -o 'at ([0-9.]*, [0-9.]*)')
    [ -z "$P1" ] && P1="$H"
    [ "$H" != "$P1" ] && SAME=0
done
ABSN=$(grep -ac 'CENTER(abs' /data/adb/gpm/helper.log)
LIN=$(grep -ac 'CENTER(linear' /data/adb/gpm/helper.log)
[ "$SAME" -eq 1 ] && ok "连按 3 次居中位置一致 ($P1)" || bad "居中位置不稳定 ($P1 vs $H)"
[ "$ABSN" -ge 3 ] && [ "$LIN" -eq 0 ] && ok "走绝对指针（abs=$ABSN linear=$LIN）" || bad "居中路径 abs=$ABSN linear=$LIN"

# Y -> Home 不锁屏
logcat -c; L=$(hc)
$VG key 308 120 2000 >/dev/null 2>&1
sleep 1.2
Hn=$(hl "$L" | grep -c 'KEYON 0 3'); Pw=$(hl "$L" | grep -c 'POWER')
[ "$Hn" -ge 1 ] && [ "$Pw" -eq 0 ] && ok "Y -> Home（无电源）" || bad "Y home=$Hn power=$Pw"

# 松手不滑行
logcat -c
$VG stick 0 20000 400 2000 >/dev/null 2>&1
sleep 0.35; logcat -c; sleep 0.9
N=$(dlog | grep -c 'ptr move')
[ "$N" -eq 0 ] && ok "松手不滑行" || bad "松手仍滑 ($N)"

# 空闲隐藏指针
$VG stick 0 20000 300 0 >/dev/null 2>&1; sleep 1
K0=$(kdev); sleep 9; K1=$(kdev)
[ "$K0" -ge 1 ] && [ "$K1" -eq 0 ] && ok "空闲隐藏指针 ($K0 -> $K1)" || bad "空闲隐藏 (K0=$K0 K1=$K1)"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

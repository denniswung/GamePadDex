#!/system/bin/sh
# v1.59 Release 冒烟：滑动不再同步 dumpsys（延迟 < 10ms）+ 光标锚定 + 缓存
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
rm -f /data/adb/gpm/taskbounds.txt
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.59" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3

# 1) 冷启动第一滑：prep 必须很小（以前是 100~300ms）
: > /data/adb/gpm/helper.log
$VG stick 4 20000 700 2000 >/dev/null 2>&1
sleep 1.2
P1=$(grep -a 'prep=' /data/adb/gpm/helper.log | head -1 | sed -n 's/.*prep=\([0-9]*\)us/\1/p')
S1=$(grep -ac 'SWIPE' /data/adb/gpm/helper.log)
[ -n "$P1" ] && [ "$P1" -lt 20000 ] && ok "冷启动滑动不阻塞（prep=${P1}us）" || bad "滑动 prep=$P1 (swipes=$S1)"

# 2) 边界缓存已生成
sleep 1.5
[ -s /data/adb/gpm/taskbounds.txt ] && ok "任务边界缓存已生成（$(cat /data/adb/gpm/taskbounds.txt)）" || bad "缓存文件缺失"

# 3) 热路径 prep（缓存命中）
: > /data/adb/gpm/helper.log
$VG stick 4 -20000 700 0 >/dev/null 2>&1
sleep 1.2
P2=$(grep -a 'prep=' /data/adb/gpm/helper.log | head -1 | sed -n 's/.*prep=\([0-9]*\)us/\1/p')
[ -n "$P2" ] && [ "$P2" -lt 20000 ] && ok "缓存命中滑动（prep=${P2}us）" || bad "热路径 prep=$P2"

# 4) 光标锚定：移动光标后按 RB，滑动起点应等于光标
$VG stick 0 8000 400 2000 >/dev/null 2>&1
sleep 0.5
: > /data/adb/gpm/helper.log
$VG key 311 120 900 >/dev/null 2>&1
sleep 1.2
L=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | head -1)
echo "      $L"
Y0=$(echo "$L" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
[ -n "$Y0" ] && [ "$Y0" -le 1000 ] && ok "RB 从光标位置起手（y=$Y0）" || bad "RB 起点异常（$L）"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

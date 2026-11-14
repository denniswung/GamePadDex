#!/system/bin/sh
# v1.58 Release 冒烟（Release 没有调试广播：只验证不需要调试入口的部分）
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.58" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
[ "$(modeval)" = "true" ] && ok "鼠标模式开" || bad "鼠标模式=$(modeval)"

# 扳机半程
logcat -c
$VG stick 2 12000 800 2000 >/dev/null 2>&1
sleep 1.0
LT=$(logcat -d -s DexPad | grep -ac 'button lt down')
[ "$LT" -ge 1 ] && ok "扳机半程触发（LT down）" || bad "扳机未触发（lt=$LT）"

# GONE 带名字
: > /data/adb/gpm/helper.log
$VG key 304 100 500 >/dev/null 2>&1
sleep 1.2
G=$(grep -a 'GONE ' /data/adb/gpm/helper.log | tail -1)
echo "$G" | grep -q 'Virtual Test Gamepad' && ok "GONE 带设备名" || bad "GONE 无名字（$G）"

# 打开目标应用（每槽参数）
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
am force-stop $PKG; sleep 1
awk 'BEGIN{done=0}
/<\/map>/ { if(!done){ print "    <string name=\"btn_y\">open_app</string>"; print "    <string name=\"par_y\">com.android.settings</string>"; done=1 } }
{ print }' "$XML" > /data/local/tmp/p.xml
cat /data/local/tmp/p.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
logcat -c
$VG hold 308 800 >/dev/null 2>&1
sleep 2.5
O=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
case "$TOP" in com.android.settings*) TOK=1;; *) TOK=0;; esac
[ "$O" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "打开目标应用（$TOP）" || bad "打开应用 O=$O top=$TOP"

# 点击仍走鼠标事件
logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1
B=$(logcat -d -s DexPad | grep -ac 'left button down'); T=$(logcat -d -s DexPad | grep -ac 'left touch down')
[ "$B" -ge 1 ] && [ "$T" -eq 0 ] && ok "A = 鼠标左键" || bad "A 注入方式 button=$B touch=$T"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

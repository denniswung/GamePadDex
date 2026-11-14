#!/system/bin/sh
# v1.58 冒烟：动作列表精简 / 应用列表可见 / 扳机阈值 / GONE 带名字 / 组合槽开应用 / 打开应用
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

# 1) 应用列表可见性 + 动作列表精简
logcat -c
am broadcast -a $PKG.QUERY -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 1.5
APPS=$(logcat -d -s DexPadDebug | grep -o 'visible=[0-9]*' | tail -1 | sed 's/visible=//')
ACT=$(logcat -d -s DexPadDebug | grep -o 'entries=[0-9]*' | tail -1 | sed 's/entries=//')
[ -n "$APPS" ] && [ "$APPS" -gt 5 ] && ok "应用列表可见（$APPS 个）" || bad "应用列表 apps=$APPS"
[ -n "$ACT" ] && [ "$ACT" -lt 40 ] && ok "动作列表已精简（$ACT 项）" || bad "动作列表 items=$ACT"

# 2) 扳机阈值：ABS_Z 半程左右就应该判定按下
logcat -c
$VG stick 2 12000 800 2000 >/dev/null 2>&1
sleep 1.0
LT=$(logcat -d -s DexPad | grep -ac 'button lt down')
[ "$LT" -ge 1 ] && ok "扳机半程可触发（LT down）" || bad "扳机半程未触发（lt=$LT）"

# 3) GONE 带名字
: > /data/adb/gpm/helper.log
$VG key 304 100 500 >/dev/null 2>&1
sleep 1.2
G=$(grep -a 'GONE ' /data/adb/gpm/helper.log | tail -1)
echo "      $G"
echo "$G" | grep -q 'Virtual Test Gamepad' && ok "GONE 带设备名" || bad "GONE 无设备名"

# 4) 每个槽位的打开应用参数 + 混合槽
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
am force-stop $PKG; sleep 1
awk 'BEGIN{done=0}
/<\/map>/ { if(!done){ print "    <string name=\"btn_r3\">open_app</string>"; print "    <string name=\"par_r3\">com.android.settings</string>"; print "    <string name=\"mix_0_action\">open_app</string>"; print "    <string name=\"mix_0_keys\">x+r3</string>"; print "    <string name=\"mix_0_value\">com.android.settings</string>"; done=1 } }
{ print }' "$XML" > /data/local/tmp/p.xml
cat /data/local/tmp/p.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
logcat -c
$VG hold 318 800 >/dev/null 2>&1
sleep 2.5
O=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
case "$TOP" in com.android.settings*) TOK=1;; *) TOK=0;; esac
[ "$O" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "打开目标应用（$TOP）" || bad "打开应用 O=$O top=$TOP"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

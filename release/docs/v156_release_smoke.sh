#!/system/bin/sh
# v1.56 Release 冒烟：右摇杆方向修正 / d-pad 连发 / 每个按键各自的目标应用
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
[ "$V" = "1.56" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
[ "$(modeval)" = "true" ] && ok "鼠标模式开" || bad "鼠标模式=$(modeval)"

am force-stop com.android.settings; sleep 1
am start -a android.settings.SETTINGS >/dev/null 2>&1
sleep 3

# 1) 右摇杆向上：必须是普通中屏拖动（起点约 30%），不能从顶部 3% 起手
: > /data/adb/gpm/helper.log
$VG stick 4 -20000 1000 2000 >/dev/null 2>&1
sleep 0.7
UP=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -1)
echo "      up-swipe: $UP"
UY0=$(echo "$UP" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
UY1=$(echo "$UP" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
if [ -n "$UY0" ] && [ -n "$UY1" ] && [ "$UY1" -gt "$UY0" ] && [ "$UY0" -gt 300 ]; then
  ok "右摇杆向上 = 中屏向下拖动（$UY0 -> $UY1）"
else
  bad "右摇杆向上 手势不对（$UY0 -> $UY1）"
fi

# 2) 右摇杆向下：反向拖动
: > /data/adb/gpm/helper.log
$VG stick 4 20000 1000 0 >/dev/null 2>&1
sleep 0.7
DN=$(grep -a 'SWIPE' /data/adb/gpm/helper.log | tail -1)
DY0=$(echo "$DN" | sed -n 's/.*SWIPE [0-9]* [0-9]*,\([0-9]*\) ->.*/\1/p')
DY1=$(echo "$DN" | sed -n 's/.* -> [0-9]*,\([0-9]*\) .*/\1/p')
if [ -n "$DY0" ] && [ -n "$DY1" ] && [ "$DY1" -lt "$DY0" ]; then
  ok "右摇杆向下 = 反向拖动（$DY0 -> $DY1）"
else
  bad "右摇杆向下 手势不对（$DY0 -> $DY1）"
fi

# 3) d-pad 连发
: > /data/adb/gpm/helper.log
$VG hat 0 1 1500 >/dev/null 2>&1
sleep 2.2
CNT=$(grep -ac 'ARROW' /data/adb/gpm/helper.log)
[ "$CNT" -gt 2 ] && ok "d-pad 按住连发（1.5s 内 $CNT 次）" || bad "d-pad 连发次数=$CNT"

# 4) 每个按键各自的目标应用
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
am force-stop $PKG; sleep 1
awk 'BEGIN{done=0}
/<\/map>/ { if(!done){ print "    <string name=\"btn_r3\">open_app</string>"; print "    <string name=\"par_r3\">com.android.settings</string>"; done=1 } }
{ print }' "$XML" > /data/local/tmp/p.xml
cat /data/local/tmp/p.xml > "$XML"
chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
: > /data/adb/gpm/helper.log
logcat -c
$VG hold 318 900 >/dev/null 2>&1
sleep 2.5
O=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
case "$TOP" in com.android.settings*) TOK=1;; *) TOK=0;; esac
[ "$O" -ge 1 ] && [ "$TOK" -eq 1 ] && ok "按键各自的目标应用（R3 -> $TOP）" || bad "目标应用 O=$O top=$TOP"

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

#!/system/bin/sh
# v1.53 Release 冒烟：杀应用 / 电源键 / 一次性居中
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
PASS=0; FAIL=0
ok(){ echo "PASS  $*"; PASS=$((PASS+1)); }
bad(){ echo "FAIL  $*"; FAIL=$((FAIL+1)); }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}' | xargs -r kill -9
sleep 1
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/adb/gpm/helper.log 2>&1 &
sleep 2
am force-stop $PKG; sleep 1
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4

V=$(dumpsys package $PKG 2>/dev/null | grep -m1 versionName | sed 's/.*=//')
[ "$V" = "1.53" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"

[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
[ "$(modeval)" = "true" ] && ok "鼠标模式开" || bad "鼠标模式=$(modeval)"

# 1) 杀应用：GUIDE 短按
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.SelfCheckActivity >/dev/null 2>&1
sleep 2
P1=$(pidof $PAD)
$VG key 316 120 900 >/dev/null 2>&1
sleep 3
P2=$(pidof $PAD)
[ -n "$P1" ] && [ -z "$P2" ] && ok "GUIDE 短按杀应用（$P1 -> 已死）" || bad "杀应用 P1=$P1 P2=$P2"

# 2) 电源键：Y+L3
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; sleep 0.6
W0=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
: > /data/adb/gpm/helper.log
$VG combo 308 317 400 >/dev/null 2>&1
sleep 2
W1=$(dumpsys power 2>/dev/null | grep -m1 -o 'mWakefulness=[A-Za-z]*')
grep -aq 'POWER' /data/adb/gpm/helper.log && ok "电源键 ($W0 -> $W1)" || bad "电源键 W0=$W0 W1=$W1"
input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1

# 3) 一次性居中：按 L3 后向左/右各推一下，落点应夹住屏幕中心
am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
$VG stick 0 20000 500 2000 >/dev/null 2>&1; sleep 0.3
: > /data/adb/gpm/helper.log
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.6
grep -aq 'CENTER(steps+gain' /data/adb/gpm/helper.log && ok "居中命令执行" || bad "居中命令未执行"
logcat -c; $VG stick 0 15000 250 0 >/dev/null 2>&1; sleep 0.4; R=$(hover)
logcat -c; $VG stick 0 -15000 250 0 >/dev/null 2>&1; sleep 0.4; L=$(hover)
RX=$(echo "$R" | cut -d, -f1); LX=$(echo "$L" | cut -d, -f1)
if [ -n "$RX" ] && [ -n "$LX" ]; then
  MID=$(( (RX + LX) / 2 ))
  if [ "$MID" -ge 1180 ] && [ "$MID" -le 1380 ]; then ok "居中落点 x≈$MID（目标 1280，右推=$RX 左推=$LX）"
  else bad "居中落点 x≈$MID（右推=$RX 左推=$LX）"; fi
else
  bad "居中后读不到指针坐标 (R=$R L=$L)"
fi

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

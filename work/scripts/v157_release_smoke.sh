#!/system/bin/sh
# v1.57 Release 冒烟：A=鼠标左键 / 长推不出屏 / 居中后点击能送达
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
[ "$V" = "1.57" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
[ "$(modeval)" = "true" ] && ok "鼠标模式开" || bad "鼠标模式=$(modeval)"

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2

# 1) 左键必须是鼠标事件
logcat -c
$VG key 304 120 800 >/dev/null 2>&1
sleep 1
B=$(logcat -d -s DexPad | grep -ac 'left button down'); T=$(logcat -d -s DexPad | grep -ac 'left touch down')
[ "$B" -ge 1 ] && [ "$T" -eq 0 ] && ok "A = 鼠标左键（不注入触摸）" || bad "A 注入方式 button=$B touch=$T"

# 2) 长推左摇杆，指针跟踪值必须留在屏幕内
logcat -c
$VG stick 0 -20000 4000 2000 >/dev/null 2>&1
$VG stick 1 -20000 4000 0 >/dev/null 2>&1
sleep 0.8
P=$(logcat -d -s DexPad | grep -a 'ptr move' | tail -1)
X=$(echo "$P" | sed -n 's/.*at \([0-9]*\),.*/\1/p')
Y=$(echo "$P" | sed -n 's/.*,\([0-9]*\)$/\1/p')
if [ -n "$X" ] && [ -n "$Y" ] && [ "$X" -ge 0 ] && [ "$X" -le 2560 ] && [ "$Y" -ge 0 ] && [ "$Y" -le 1600 ]; then
  ok "长推后光标仍在屏内（$X,$Y）"
else
  bad "光标位置越界（$X,$Y）"
fi

# 3) L3 居中后按 A：鼠标点击必须送达应用，且落点接近屏幕中心
logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.5
logcat -c
$VG key 304 120 900 >/dev/null 2>&1
sleep 1.2
CX=$(logcat -d -s PadProbe | grep -a 'MOUSE/click-down' | tail -1 | sed -n 's/.*x=\([0-9.]*\).*/\1/p')
C=$(logcat -d -s PadProbe | grep -ac 'MOUSE/click')
[ "$C" -ge 1 ] && ok "居中后点击送达应用（$C 条 mouse 事件）" || bad "点击没送达（$C）"
if [ -n "$CX" ]; then
  CXI=${CX%.*}
  if [ "$CXI" -ge 1100 ] && [ "$CXI" -le 1460 ]; then
    ok "点击落点接近屏幕中心（x=$CX）"
  else
    bad "点击落点偏离（x=$CX）"
  fi
else
  bad "读不到点击坐标"
fi

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

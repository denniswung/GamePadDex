#!/system/bin/sh
# v1.54 Release 冒烟：A=触摸点击 / LT·RT=双指缩放 / d-pad 模式缩放=Ctrl+- / 打开目标应用
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
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
[ "$V" = "1.54" ] && ok "版本 $V" || bad "版本=$V"
logcat -d -s DexPad | grep -q 'hb ready=true' && ok "助手链路" || bad "助手链路"

[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
[ "$(modeval)" = "true" ] && ok "鼠标模式开" || bad "鼠标模式=$(modeval)"

am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2

# 1) A = 触摸点击 + 长按
logcat -c; : > /data/adb/gpm/helper.log
$VG key 304 120 800 >/dev/null 2>&1
sleep 1
D=$(logcat -d -s DexPad | grep -ac 'left touch down'); U=$(logcat -d -s DexPad | grep -ac 'left touch up')
T=$(grep -ac 'TOUCH down' /data/adb/gpm/helper.log)
[ "$D" -ge 1 ] && [ "$U" -ge 1 ] && [ "$T" -ge 1 ] && ok "A = 屏幕点击（touch down/up）" || bad "A 点击 down=$D up=$U touch=$T"

logcat -c; : > /data/adb/gpm/helper.log
$VG hold 304 900 >/dev/null 2>&1
sleep 1.4
H=$(grep -ac 'TOUCH down' /data/adb/gpm/helper.log); HU=$(grep -ac 'TOUCH up' /data/adb/gpm/helper.log)
[ "$H" -ge 1 ] && [ "$HU" -ge 1 ] && ok "A 长按（按住 900ms 后抬起）" || bad "A 长按 down=$H up=$HU"

# 2) LT/RT = 双指缩放（普通模式）
logcat -c; : > /data/adb/gpm/helper.log
$VG hold 312 800 >/dev/null 2>&1
sleep 1.2
P1=$(logcat -d -s DexPad | grep -ac 'pinch zoom out'); S1=$(grep -ac 'PINCH start dir=-1' /data/adb/gpm/helper.log)
[ "$P1" -ge 1 ] && [ "$S1" -ge 1 ] && ok "LT = 双指缩小（以光标为基准）" || bad "LT zoom P=$P1 S=$S1"

logcat -c; : > /data/adb/gpm/helper.log
$VG hold 313 800 >/dev/null 2>&1
sleep 1.2
P2=$(logcat -d -s DexPad | grep -ac 'pinch zoom in'); S2=$(grep -ac 'PINCH start dir=1' /data/adb/gpm/helper.log)
[ "$P2" -ge 1 ] && [ "$S2" -ge 1 ] && ok "RT = 双指放大（以光标为基准）" || bad "RT zoom P=$P2 S=$S2"

# 3) d-pad 模式下缩放 = Ctrl +/-
logcat -c; : > /data/adb/gpm/helper.log
($VG hat 0 1 3500 >/dev/null 2>&1) &
sleep 0.35
$VG key 312 120 700 >/dev/null 2>&1
sleep 1.2
K=$(grep -ac 'KCOMBO' /data/adb/gpm/helper.log); Z=$(logcat -d -s DexPad | grep -ac 'zoom out -> \[')
[ "$K" -ge 1 ] && [ "$Z" -ge 1 ] && ok "d-pad 模式 LT = Ctrl + -" || bad "d-pad zoom KCOMBO=$K combo=$Z"
wait 2>/dev/null

# 4) 打开目标应用（release 没有调试广播：直接改 prefs 再重启）
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
if [ -n "$XML" ]; then
  am force-stop $PKG; sleep 1
  grep -q 'target_package' "$XML" || sed -i 's#</map>#    <string name="target_package">com.android.settings</string>\n</map>#' "$XML"
  grep -q 'btn_r3' "$XML" || sed -i 's#</map>#    <string name="btn_r3">open_app</string>\n</map>#' "$XML"
  sleep 0.5
  am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
  sleep 3
  input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
  logcat -c; : > /data/adb/gpm/helper.log
  $VG key 318 120 900 >/dev/null 2>&1
  sleep 3
  O=$(logcat -d -s DexPad | grep -ac 'open app com.android.settings')
  TOP=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')
  case "$TOP" in com.android.settings*) TOPOK=1;; *) TOPOK=0;; esac
  [ "$O" -ge 1 ] && [ "$TOPOK" -eq 1 ] && ok "打开目标应用（$TOP）" || bad "打开目标应用 O=$O top=$TOP"
else
  bad "找不到 prefs 文件"
fi

CR=$(logcat -b crash -d 2>/dev/null | grep -c "$PKG")
[ "$CR" -eq 0 ] && ok "无崩溃" || bad "崩溃 $CR"

echo "----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"

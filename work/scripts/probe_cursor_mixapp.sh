#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
top(){ dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }
start_engine(){ am force-stop $PKG; sleep 1; am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1; sleep 4; }

wake; sleep 1

echo "=== piliplus 包名 ==="
pm list packages 2>/dev/null | grep -iE 'pili|bili' | head -5

echo
echo "=== A) d-pad 确认后摇杆移动（看指针估计是否卡住）==="
am force-stop $PAD; sleep 1
am start -n $PAD/.ui.AutoTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1   # 居中
sleep 1.2
logcat -c
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.4
$VG hat 0 1 250 >/dev/null 2>&1
sleep 0.4
$VG key 304 120 700 >/dev/null 2>&1    # 确认
sleep 1.0
echo "--- 确认后向四个方向各推 1.2s ---"
$VG stick 0 20000 1200 2000 >/dev/null 2>&1   # 右
$VG stick 0 -20000 1200 0 >/dev/null 2>&1     # 左
$VG stick 1 20000 1200 0 >/dev/null 2>&1      # 下
$VG stick 1 -20000 1200 0 >/dev/null 2>&1     # 上
sleep 0.5
echo "--- 引擎指针日志（看 at 坐标是否卡在边界）---"
logcat -d -s DexPad | grep -a 'ptr move' | tail -14

echo
echo "--- 每次推完按 A 看点击落点（padtest 日志）---"
: > /data/adb/gpm/helper.log
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "padtest hover/click: $(logcat -d -s PadProbe | grep -aE 'hover|click' | tail -4 | tr '\n' '|')"
echo "engine: $(logcat -d -s DexPad | grep -aE 'A pressed|left button|left touch' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

echo
echo "=== B) Start+Up 打开应用（模拟用户配置）==="
start_engine
# 找一个空槽位写入 start+up -> open_app
SLOT=""
for i in $(seq 0 23); do
  K=$(grep -c "name=\"mix_${i}_keys\"" "$XML" 2>/dev/null)
  if [ "$K" = "0" ]; then SLOT=$i; break; fi
done
[ -z "$SLOT" ] && SLOT=20
echo "使用槽位 mix_$SLOT"
am force-stop $PKG; sleep 1
awk -v s="$SLOT" 'BEGIN{d=0}
/<\/map>/ { if(!d){ printf "    <string name=\"mix_%s_keys\">start+up</string>\n", s; printf "    <string name=\"mix_%s_action\">open_app</string>\n", s; printf "    <string name=\"mix_%s_value\">com.android.settings</string>\n", s; d=1 } }
{ print }' "$XML" > /data/local/tmp/pp.xml
cat /data/local/tmp/pp.xml > "$XML"; chmod 600 "$XML"
sleep 0.5
am start-foreground-service -n $PKG/.EngineService >/dev/null 2>&1
sleep 4
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }
input keyevent KEYCODE_HOME >/dev/null 2>&1; sleep 1.5
logcat -c; : > /data/adb/gpm/helper.log
$VG keyhat 315 1 400 >/dev/null 2>&1      # START 按住 + 方向键上
sleep 2.5
echo "engine: $(logcat -d -s DexPad | grep -aE 'open app|mix|single for start' | tail -4 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "after: $(top)"

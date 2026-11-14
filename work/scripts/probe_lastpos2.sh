#!/system/bin/sh
PKG=com.dennis.dexpad
PAD=com.dennis.padtest
VG=/data/local/tmp/vgpad
XML=$(ls /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1)
wake(){ input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' "$XML" 2>/dev/null | sed 's/.*value="//;s/"//'; }
wake; sleep 1
[ "$(modeval)" = "true" ] || { $VG key 167 120 900 >/dev/null 2>&1; sleep 1.2; }

am force-stop $PAD; sleep 0.5
am start -n $PAD/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2.5
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.2

logcat -c; : > /data/adb/gpm/helper.log
$VG stick 0 20000 600 2000 >/dev/null 2>&1
$VG stick 1 20000 400 0 >/dev/null 2>&1
sleep 0.6
LASTMOVE=$(logcat -d -s DexPad | grep -a 'ptr move' | tail -1)
ESTX=$(echo "$LASTMOVE" | sed -n 's/.*at \([0-9]*\),.*/\1/p')
ESTY=$(echo "$LASTMOVE" | sed -n 's/.*,\([0-9]*\)$/\1/p')
echo "移动后估算: $ESTX,$ESTY"
echo "真实光标(padtest): $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -1)"

echo "--- 空闲 10 秒 ---"
sleep 10
logcat -c
$VG stick 0 4000 200 2000 >/dev/null 2>&1
sleep 1.5
SHOW=$(logcat -d -s DexPad | grep -a 'pointer shown at last position' | tail -1)
echo "恢复日志: $SHOW"
RX=$(echo "$SHOW" | sed -n 's/.*position \([0-9]*\),.*/\1/p')
RY=$(echo "$SHOW" | sed -n 's/.*,\([0-9]*\) .*/\1/p')
echo "恢复坐标: $RX,$RY （上次 $ESTX,$ESTY）"
sleep 0.5
echo "真实光标(padtest): $(logcat -d -s PadProbe | grep -a 'MOUSE/hover' | tail -2 | tr '\n' '|')"
logcat -c
$VG key 304 120 700 >/dev/null 2>&1
sleep 1
echo "点击落点: $(logcat -d -s PadProbe | grep -a 'click-down' | tail -1)"

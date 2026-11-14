#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

EV=$(grep -A4 -i 'Gamepad Touch Panel' /proc/bus/input/devices | grep -o 'event[0-9]*' | head -1)
echo "touch node=$EV"

echo "=== 双指缩放期间的内核事件（应有两个 SLOT/TRACKING_ID）==="
if [ -n "$EV" ]; then
  ( timeout 2 getevent -l /dev/input/$EV > /data/local/tmp/pinch_ev.txt 2>&1 & )
  sleep 0.4
fi
logcat -c
$VG hold 312 900 >/dev/null 2>&1
sleep 1.2
echo "  指针数统计: $(grep -c 'ABS_MT_TRACKING_ID' /data/local/tmp/pinch_ev.txt 2>/dev/null) 个 tracking 事件"
echo "  slot 事件: $(grep -c 'ABS_MT_SLOT' /data/local/tmp/pinch_ev.txt 2>/dev/null)"
head -8 /data/local/tmp/pinch_ev.txt 2>/dev/null
echo "  引擎: $(logcat -d -s DexPad | grep -a pinch | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

echo
echo "=== RT = 放大（应以光标为基准）==="
logcat -c
$VG hold 313 900 >/dev/null 2>&1
sleep 1.2
echo "  引擎: $(logcat -d -s DexPad | grep -a pinch | tail -2 | sed 's/^.*DexPad  : //' | tr '\n' '|')"

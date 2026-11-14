#!/system/bin/sh
PKG=com.dennis.dexpad
hcmd(){ am broadcast -a $PKG.HCMD -n $PKG/.DebugReceiver --es cmd "$1" >/dev/null 2>&1; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
echo "focus: $(dumpsys window 2>/dev/null | grep mCurrentFocus | tail -1)"

hcmd "q 2560 1600" >/dev/null 2>&1; sleep 0.4
EV=$(grep -A4 -i 'Gamepad Touch Panel' /proc/bus/input/devices | grep -o 'event[0-9]*' | head -1)
echo "node=$EV"

if [ -n "$EV" ]; then
  ( timeout 3 getevent -l /dev/input/$EV > /data/local/tmp/tev.txt 2>&1 & )
  sleep 0.5
fi
logcat -c
hcmd "k 1280 800 1"; sleep 0.4; hcmd "k 1280 800 0"; sleep 1.2

echo "=== 原始事件（内核侧）==="
cat /data/local/tmp/tev.txt 2>/dev/null | head -14
echo "=== 应用日志（全部 tag，含 touch）==="
logcat -d 2>/dev/null | grep -iE 'PadProbe|touch' | tail -10
echo "=== 助手日志 ==="
grep -aE 'TOUCH' /data/adb/gpm/helper.log | tail -3

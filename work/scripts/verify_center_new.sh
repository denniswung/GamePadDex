#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2

if [ "$(modeval)" != "true" ]; then
  echo "mode=off -> 按 SHARE 打开"
  $VG key 167 120 800 >/dev/null 2>&1
  sleep 1.2
fi
echo "mode_on=$(modeval)"

for i in 1 2; do
  $VG stick 0 20000 400 2000 >/dev/null 2>&1
  sleep 0.3
  $VG stick 4 20000 400 0 >/dev/null 2>&1
  sleep 0.4
  echo "起点 hover: $(hover)"
  : > /data/adb/gpm/helper.log
  $VG key 317 100 1200 >/dev/null 2>&1
  sleep 1.6
  echo "  helper: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"
  logcat -c
  $VG stick 0 600 100 0 >/dev/null 2>&1
  sleep 0.5
  echo "  居中后 hover: $(hover)   期望约 1280,800"
done

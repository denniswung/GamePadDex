#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
hover(){ logcat -d -s PadProbe 2>/dev/null | grep 'MOUSE/hover' | tail -1 | sed -n 's/.*x=\([0-9.]*\) y=\([0-9.]*\).*/\1,\2/p'; }
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
nudge(){ logcat -c; $VG stick 0 "$1" 250 0 >/dev/null 2>&1; sleep 0.4; hover; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.CursorTestActivity >/dev/null 2>&1
sleep 2
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }
echo "mode_on=$(modeval)"

# 推一段，确认 hover 可用
$VG stick 0 20000 500 2000 >/dev/null 2>&1; sleep 0.3
echo "推后 hover: $(nudge 15000)"

# 居中
: > /data/adb/gpm/helper.log
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.6
echo "helper: $(grep -a 'CENTER' /data/adb/gpm/helper.log | tail -1)"

R=$(nudge 15000)
sleep 0.3
L=$(nudge -15000)
echo "居中后 右推=$R  左推=$L"
echo "（若居中成功：右推 x 应略大于 1280，左推 x 略小于 1280）"

#!/system/bin/sh
PKG=com.dennis.dexpad
VG=/data/local/tmp/vgpad
modeval(){ grep -oE 'name="mode_on" value="[a-z]+"' /data/misc/*/prefs/$PKG/dexpad.xml 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }

input keyevent KEYCODE_WAKEUP >/dev/null 2>&1; wm dismiss-keyguard >/dev/null 2>&1; sleep 1
[ "$(modeval)" != "true" ] && { $VG key 167 120 800 >/dev/null 2>&1; sleep 1.2; }

am force-stop com.dennis.padtest; sleep 0.5
am start -n com.dennis.padtest/.ui.ScrollTestActivity >/dev/null 2>&1
sleep 2
echo "前台: $(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | sed 's/.*u0 //;s/ .*//')"

echo "--- L3 居中 ---"
logcat -c
$VG key 317 100 1200 >/dev/null 2>&1
sleep 1.5

echo "--- 按 A 点击 ---"
logcat -c
$VG key 304 120 900 >/dev/null 2>&1
sleep 1.2
echo "引擎: $(logcat -d -s DexPad | grep -aE 'left button|left touch|cursor centered' | tail -3 | sed 's/^.*DexPad  : //' | tr '\n' '|')"
echo "padtest: $(logcat -d -s PadProbe | grep -aiE 'mouse' | tail -3 | sed 's/^.*PadProbe: //' | tr '\n' '|')"
echo "helper: $(grep -aE 'CENTER|BTN|MOUSE' /data/adb/gpm/helper.log | tail -3 | tr '\n' '|')"

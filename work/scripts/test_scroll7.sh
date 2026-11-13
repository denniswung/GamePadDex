#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad
killall gpminput 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock /data/data/$PKG/files/snap_*.png
mkdir -p /data/data/$PKG/files
(setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 </dev/null &)
sleep 2
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 4
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== attach / mode =="
logcat -d -s GpmService:V 2>/dev/null | grep -E "ATTACH|mouse mode" | tail -2
echo "== move pointer with stick: right+down (real pointer moves) =="
(/data/local/tmp/vgpad stick 0 20000 1500 2600 >/dev/null 2>&1 &)
sleep 5
echo "== then scroll with right stick =="
logcat -c
(/data/local/tmp/vgpad stick 4 -30000 1500 2600 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmGesture:I 2>/dev/null | grep "scroll on display" | tail -2
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
echo done

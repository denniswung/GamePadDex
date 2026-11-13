#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad

killall gpminput 2>/dev/null
sleep 1
rm -f /data/data/$PKG/files/gpm.sock
/data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 &
DPID=$!
sleep 2
echo "daemon=$DPID alive=$(kill -0 $DPID 2>/dev/null && echo yes || echo no)"

settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -d -s GpmRootInput:V GpmService:V 2>/dev/null | grep -E "socket|helper ready|mouse mode" | tail -3

echo "== right stick down (linux ABS_RY=4) =="
(/data/local/tmp/vgpad stick 4 30000 1800 2600 >/dev/null 2>&1 &)
sleep 6
logcat -d -s GpmService:V GpmPointer:V GpmRootInput:V 2>/dev/null | grep -E "gamepad:|rstick|wheel|scroll" | tail -10
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
kill $DPID 2>/dev/null

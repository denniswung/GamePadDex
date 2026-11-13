#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad
pkill -f "gpm/gpminput" 2>/dev/null
sleep 0.8
rm -f /data/data/$PKG/files/gpm.sock
mkdir -p /data/data/$PKG/files
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 </dev/null &
sleep 2
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== right stick (linux ABS_RY=4 -> AXIS_RY) =="
(/data/local/tmp/vgpad stick 4 30000 1500 2600 >/dev/null 2>&1 &)
sleep 5
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "rstick|wheel" | tail -6
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1

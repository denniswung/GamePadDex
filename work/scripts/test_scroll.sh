#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
chmod 755 /data/local/tmp/vgpad
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
echo "== mode =="
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "mouse mode|native" | tail -2
echo "== right stick down (ABS_RZ=14) =="
(/data/local/tmp/vgpad stick 14 30000 1500 2400 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "rstick|wheel" | tail -8
echo "== right stick via ABS_Z=11 =="
(/data/local/tmp/vgpad stick 11 30000 1200 2400 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | grep -E "rstick|wheel" | tail -6
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1

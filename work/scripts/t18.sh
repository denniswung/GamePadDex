#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
pkill -f "test.sock" 2>/dev/null
chmod 755 /data/local/tmp/vgpad
logcat -c
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
echo "== connection =="
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | grep -E "socket|helper ready" | tail -3

echo "== L3 #1 =="
(/data/local/tmp/vgpad key 106 120 2500 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -3

echo "== L3 #2 =="
(/data/local/tmp/vgpad key 106 120 2500 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -3

echo "== daemon still alive? =="
ps -A -o PID,ARGS | grep "gpm/gpminput" | grep -v grep

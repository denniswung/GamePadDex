#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService

echo "== enable accessibility =="
settings put secure enabled_accessibility_services "$SVC"
settings put secure accessibility_enabled 1
sleep 1

echo "== start app once (creates prefs) =="
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 2
am force-stop $PKG >/dev/null 2>&1
sleep 0.5
# restart the accessibility service by toggling
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$SVC"
sleep 2

echo "== service process =="
ps -A -o PID,ARGS | grep -i "com.dennis.gamepadmouse" | head -3

echo "== log after start =="
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V AndroidRuntime:E 2>/dev/null | tail -25

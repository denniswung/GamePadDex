#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService

echo "== disable the original app's accessibility service =="
settings put secure enabled_accessibility_services "$SVC"
settings put secure accessibility_enabled 1
sleep 2

echo "== toggle mouse mode ON =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 1.5
logcat -d -s GpmService:V GpmPointer:V GpmRootInput:V 2>/dev/null | tail -8

echo "== cursor window =="
dumpsys window windows 2>/dev/null | grep -A3 "u0 com.dennis.gamepadmouse}:" | grep -E "mAttrs=" | head -4

echo "== stick right =="
/data/local/tmp/vgpad stick 0 30000 1200 2>/dev/null
sleep 0.3
dumpsys window windows 2>/dev/null | grep -A3 "u0 com.dennis.gamepadmouse}:" | grep -E "mAttrs=" | head -4
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | tail -4

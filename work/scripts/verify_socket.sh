#!/system/bin/sh
PKG=com.dennis.gamepadmouse
logcat -c
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 4
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | head -20

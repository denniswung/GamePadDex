#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
chmod 755 /data/local/tmp/vgpad
logcat -c
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 3
echo "== helper =="
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | grep -E "helper ready|socket" | tail -2
echo "== L3 press #1 (root path, expect exactly one ON) =="
(/data/local/tmp/vgpad key 106 120 2500 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -3
echo "== L3 press #2 (expect exactly one OFF) =="
(/data/local/tmp/vgpad key 106 120 2500 >/dev/null 2>&1 &)
sleep 4.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -3

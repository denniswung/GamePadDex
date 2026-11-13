#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
settings put secure enabled_accessibility_services "$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
settings put secure accessibility_enabled 1
sleep 0.3
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | tail -8
echo "== launch UI on DeX =="
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 2
echo "== snap =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
ls -l /data/data/$PKG/files/ 2>&1 | tail -3
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -1

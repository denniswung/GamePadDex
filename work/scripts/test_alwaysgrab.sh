#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SU=/data/data/$PKG/shared_prefs/GamepadMousePrefs.xml
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 4
logcat -c
echo "== mouse mode stays OFF, but the pad must be grabbed by default =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|gamepad:" | tail -6
echo "== press A with mouse mode OFF (stock input must not react) =="
/data/local/tmp/vgpad key 304 120 2600 >/dev/null 2>&1
sleep 3
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "grabbed|gamepad:|root helper" | tail -4

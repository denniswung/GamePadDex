#!/system/bin/sh
PKG=com.dennis.gamepadmouse
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 1
rm -f /data/data/$PKG/files/gpm.sock
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
echo "helpers=$(ps -A | grep -c gpminput)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
logcat -c
echo "== state (mouse mode should be OFF, pad grabbed anyway) =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready|mouse mode" | tail -6
echo "== press A (stock handler must not see it) =="
/data/local/tmp/vgpad key 304 120 2600 >/dev/null 2>&1
sleep 3
logcat -d -s GpmRootInput:I 2>/dev/null | grep -E "grabbed|gamepad:" | tail -3

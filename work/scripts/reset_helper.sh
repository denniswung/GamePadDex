#!/system/bin/sh
PKG=com.dennis.gamepadmouse
pkill -f 'gpm_dex/service.sh' 2>/dev/null
sleep 1
killall gpminput 2>/dev/null
pkill -f ScrollInject 2>/dev/null
sleep 1
echo "before=$(ps -A | grep -c gpminput)"
rm -f /data/data/$PKG/files/gpm.sock
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
echo "helpers=$(ps -A | grep -c gpminput)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 5
logcat -c
echo "== state =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready|mouse mode" | tail -5
echo "== final helper count =="
ps -A | grep -c gpminput

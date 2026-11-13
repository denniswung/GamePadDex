#!/system/bin/sh
PKG=com.dennis.gamepadmouse
pkill -f 'gpm_dex/service.sh'
sleep 1
killall gpminput
pkill -f ScrollInject
sleep 2
echo "after-kill helpers=$(ps -A | grep gpminput | grep -v grep | wc -l)"
echo "loops=$(ps -A | grep 'service.sh' | grep -v grep | wc -l)"
rm -f /data/data/$PKG/files/gpm.sock
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A | grep gpminput | grep -v grep | wc -l)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 5
logcat -c
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready" | tail -4
echo "final=$(ps -A | grep gpminput | grep -v grep | wc -l)"

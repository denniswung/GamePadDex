#!/system/bin/sh
PKG=com.dennis.gamepadmouse
rm -f /data/adb/gpm/service.pid
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "first=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
echo "second=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
rm -f /data/data/$PKG/files/gpm.sock
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
logcat -c
echo "== state =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready" | tail -4
echo "final=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"

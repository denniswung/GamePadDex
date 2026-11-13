#!/system/bin/sh
PKG=com.dennis.gamepadmouse
# these processes run as root: a plain killall from the shell uid is a no-op
su -c 'pkill -f gpm_dex/service.sh; killall gpminput; pkill -f ScrollInject; sleep 1' 2>/dev/null
sleep 2
echo "after-kill=$(ps -A | grep -c gpminput)"
rm -f /data/data/$PKG/files/gpm.sock
su -c "setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &" 2>/dev/null
sleep 6
echo "helpers=$(ps -A | grep -c gpminput)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 5
logcat -c
echo "== state =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready|mouse mode" | tail -5
echo "final=$(ps -A | grep -c gpminput)"

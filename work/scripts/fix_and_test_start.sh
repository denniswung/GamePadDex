#!/system/bin/sh
PKG=com.dennis.gamepadmouse
# stop the churning supervisor (it keeps spawning helpers that exit on the lock)
pkill -f 'gpm_dex/service.sh'
sleep 1
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
echo "supervisors=$(ps -A | grep 'service.sh' | grep -v grep | wc -l)"
# force the app to reconnect to the live helper
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
logcat -c
echo "== connection =="
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "helper ready|connected to helper|gamepad:|grabbed:|always-grab" | tail -6
echo "== press START (linux 315) -> mapped to dex_fullscreen =="
/data/local/tmp/vgpad key 315 120 3000 >/dev/null 2>&1
sleep 4
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction|dex_fullscreen" | tail -4

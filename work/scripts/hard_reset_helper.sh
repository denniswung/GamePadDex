#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
# hard reset: no helpers, no supervisors, no stale socket/lock
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -f 'gpm_dex/service.sh'
pkill -f ScrollInject
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
# one helper only, started directly (no supervisor churn)
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/data/local/tmp/helper.log 2>&1 </dev/null &
sleep 3
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l) socket=$(ls /data/data/$PKG/files/gpm.sock 2>/dev/null | wc -l)"
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
logcat -c
echo "== connection =="
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected|helper ready|gamepad:|grabbed:" | tail -6
echo "== helper stderr =="
tail -4 /data/local/tmp/helper.log
echo "== press START (315) -> dex_fullscreen =="
/data/local/tmp/vgpad key 315 120 3000 >/dev/null 2>&1
sleep 4
logcat -d -s GpmService:I 2>/dev/null | grep -E "mapped key|fireAction|dex_fullscreen" | tail -4

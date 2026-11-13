#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
# stop everything and start exactly one supervised helper
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -9 -f ScrollInject
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 5
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l) sups=$(ps -A | grep 'gpm_dex' | grep -v grep | wc -l)"
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 10
echo "== procs after app start =="
ps -A -o PID,NAME | grep -E 'gpminput|ScrollInject' | grep -v grep
echo "== log =="
tail -6 /data/local/tmp/gpm-module.log
echo "== app connection =="
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected to helper|helper ready|grabbed" | tail -4

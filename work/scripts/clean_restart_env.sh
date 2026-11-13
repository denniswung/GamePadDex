#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
# kill every supervisor and helper (root-owned), then start exactly one
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -9 -f ScrollInject
sleep 2
echo "after-kill=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l) sups=$(ps -A | grep 'gpm_dex' | grep -v grep | wc -l)"
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
# let the app connect so the helper spawns the injector
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
echo "== injector process =="
ps -A -o PID,NAME | grep ScrollInject | grep -v grep
echo "== helper log =="
tail -6 /data/local/tmp/gpm-module.log

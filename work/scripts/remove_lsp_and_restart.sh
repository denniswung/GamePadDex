#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
echo "== remove the LSPosed module =="
pm uninstall com.dennis.dexfs 2>&1 | head -2
rm -rf /data/app/*/com.dennis.dexfs* 2>/dev/null
echo "== reset and start the gpm module =="
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -9 -f ScrollInject
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
echo "== app reconnect =="
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
logcat -c
echo "== state =="
ps -A -o PID,NAME | grep -E 'gpminput|ScrollInject' | grep -v grep
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected to helper|helper ready|injector|ERR" | tail -5
echo "== helper log =="
tail -4 /data/local/tmp/gpm-module.log

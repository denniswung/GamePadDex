#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
echo "== retire the legacy service.d script (KSU module owns startup now) =="
for p in $(ps -A -o PID,ARGS | grep '99-gpm-helper.sh' | grep -v grep | awk '{print $1}'); do kill -9 $p; done
if [ -f /data/adb/service.d/99-gpm-helper.sh ]; then
    mv /data/adb/service.d/99-gpm-helper.sh /data/adb/service.d/99-gpm-helper.sh.disabled
fi
ls -l /data/adb/service.d/ 2>/dev/null
echo "== clean restart =="
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
pkill -9 -f ScrollInject
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
echo "== state =="
ps -A -o PID,NAME | grep -E 'gpminput|ScrollInject' | grep -v grep
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected to helper|helper ready|injector ready|ERR" | tail -4
echo "== helper log =="
tail -4 /data/local/tmp/gpm-module.log

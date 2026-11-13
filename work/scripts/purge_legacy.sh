#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
echo "== move the legacy script out of service.d (KSU runs every file there) =="
mkdir -p /data/adb/gpm
mv /data/adb/service.d/99-gpm-helper.sh.disabled /data/adb/gpm/99-gpm-helper.sh.bak 2>/dev/null
ls -l /data/adb/service.d/ 2>/dev/null
for p in $(ps -A -o PID,ARGS | grep '99-gpm-helper' | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 1
echo "== start the KSU module supervisor (single) =="
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 2
rm -f /data/adb/gpm/helper.lock /data/adb/gpm/service.pid /data/data/$PKG/files/gpm.sock
: > /data/local/tmp/gpm-module.log
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
echo "supervisors:"
ps -A -o PID,ARGS 2>/dev/null | grep -E 'gpm_dex/service.sh|99-gpm' | grep -v grep
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
logcat -c
echo "== app =="
logcat -d -s GpmRootInput:I GpmService:I 2>/dev/null | grep -E "connected to helper|helper ready|ERR" | tail -3
echo "== log =="
tail -3 /data/local/tmp/gpm-module.log

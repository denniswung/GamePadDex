#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
# hard reset: kill everything by pid
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p 2>/dev/null; done
pkill -f 'gpm_dex/service.sh' 2>/dev/null
sleep 2
echo "after-kill=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput; chmod 755 /data/adb/gpm/gpminput
cp -f /data/local/tmp/gpminput $MOD/gpminput; chmod 755 $MOD/gpminput
rm -f /data/data/$PKG/files/gpm.sock /data/adb/gpm/service.pid /data/adb/gpm/helper.lock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "one=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
# try to start a second one: the flock must reject it
setsid /data/adb/gpm/gpminput --socket /data/data/$PKG/files/gpm.sock >/dev/null 2>&1 </dev/null &
sleep 3
echo "after-second=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
# now start the app and make sure it does not spawn a third
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
logcat -c
echo "== state =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready|connected to helper" | tail -5
echo "final=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"

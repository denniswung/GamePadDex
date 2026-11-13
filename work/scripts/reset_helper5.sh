#!/system/bin/sh
PKG=com.dennis.gamepadmouse
# kill every helper by pid (root owns them)
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p 2>/dev/null; done
pkill -f 'gpm_dex/service.sh' 2>/dev/null
sleep 2
echo "after-kill=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
rm -f /data/data/$PKG/files/gpm.sock /data/adb/gpm/service.pid
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "one=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
# a second start must exit immediately thanks to the socket check
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 4
echo "two=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 6
logcat -c
echo "== state =="
logcat -d -s GpmService:I GpmRootInput:I 2>/dev/null | grep -E "always-grab|grabbed|helper ready" | tail -4
echo "final=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"

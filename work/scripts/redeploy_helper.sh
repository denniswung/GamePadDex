#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
echo "before deploy: $(stat -c%s /data/adb/gpm/gpminput 2>/dev/null) / $(stat -c%s $MOD/gpminput 2>/dev/null)"
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
cp -f /data/local/tmp/gpminput /data/adb/gpm/gpminput
chmod 755 /data/adb/gpm/gpminput
echo "after deploy:  $(stat -c%s /data/adb/gpm/gpminput) / $(stat -c%s $MOD/gpminput)"
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 2
rm -f /data/adb/gpm/helper.lock /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
echo "helpers=$(ps -A -o PID,NAME | grep gpminput | grep -v grep | wc -l)"
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 8
logcat -c
/data/local/tmp/vgpad stick 4 30000 1800 2600 >/dev/null 2>&1 &
sleep 7
logcat -d 2>/dev/null | grep -E 'axis=13|axis=14|wheel |GpmAxis' | tail -5

#!/system/bin/sh
PKG=com.dennis.gamepadmouse
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 2
rm -f /data/adb/gpm/helper.lock /data/data/$PKG/files/gpm.sock
setsid sh /data/adb/modules/gpm_dex/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
echo "== devices the helper sees =="
logcat -d -s GpmRootInput:I 2>/dev/null | grep -E "gamepad:|grabbed|DEV" | tail -8
echo "== input device names =="
dumpsys input 2>/dev/null | grep -E "^  Device [0-9]+:" | head -12

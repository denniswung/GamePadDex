#!/system/bin/sh
PKG=com.dennis.gamepadmouse
MOD=/data/adb/modules/gpm_dex
cp -f /data/local/tmp/gpminput $MOD/gpminput
chmod 755 $MOD/gpminput
pkill -9 -f 'gpm_dex/service.sh'
for p in $(ps -A -o PID,NAME | grep gpminput | grep -v grep | awk '{print $1}'); do kill -9 $p; done
sleep 2
rm -f /data/adb/gpm/helper.lock /data/data/$PKG/files/gpm.sock
setsid sh $MOD/service.sh >/dev/null 2>&1 </dev/null &
sleep 6
am force-stop $PKG
sleep 1
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
sleep 7
logcat -c
echo "== enable mouse mode (grab) =="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 4
echo "== grab diagnostics =="
logcat -d 2>/dev/null | grep -E "GRAB_REQ|GRAB_AFTER_SCAN|GRABBED|ERR grab|GONE_|gamepad:|grabbed:" | tail -14

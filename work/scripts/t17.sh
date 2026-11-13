#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"
BIN=/data/adb/gpm/gpminput
SOCK=/data/data/$PKG/files/gpm.sock

chmod 755 /data/local/tmp/gpminput /data/local/tmp/vgpad
cp -f /data/local/tmp/gpminput $BIN
chmod 755 $BIN
pkill -f "gpm/gpminput" 2>/dev/null
pkill -f "files/gpminput" 2>/dev/null
sleep 0.6
rm -f $SOCK
mkdir -p /data/data/$PKG/files
nohup $BIN --socket $SOCK >/data/local/tmp/gpm-daemon.log 2>&1 &
sleep 1.2
ls -l $SOCK 2>&1

logcat -c
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
echo "== session 1 =="
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | grep -E "socket|helper ready|gamepad" | tail -3

echo "== restart the accessibility service (daemon must survive + re-accept) =="
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$A11Y"
sleep 3
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | grep -E "socket|helper ready" | tail -3
ps -A -o PID,ARGS | grep "gpm/gpminput" | grep -v grep

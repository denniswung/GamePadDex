#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
pkill -f gpminput 2>/dev/null; sleep 0.4
rm -f /data/data/$PKG/files/snap_*.png
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 1.2
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 2.5
logcat -c
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 1.5
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action snap >/dev/null 2>&1
sleep 2
ls -l /data/data/$PKG/files/ | tail -5
logcat -d -s GpmService:V GpmRootInput:V 2>/dev/null | tail -8

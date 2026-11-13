#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
pkill -f gpminput 2>/dev/null
sleep 0.5
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 2
echo "== socket =="
ls -l $SOCK 2>&1
echo "== helper stderr =="
cat /data/local/tmp/gpminput.socklog 2>&1 | head -4
logcat -c
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 6
echo "== logs =="
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | head -30

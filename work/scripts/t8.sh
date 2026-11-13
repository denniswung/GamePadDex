#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
pkill -f gpminput 2>/dev/null; sleep 0.4
rm -f /data/data/$PKG/files/snap_*.png /data/local/tmp/snap_*.png
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 1.2
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 2.5
logcat -c
echo "== toggle ON =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 1.5
echo "== press A =="
(/data/local/tmp/vgpad key 304 120 2600 >/dev/null 2>&1 &)
sleep 4.5
echo "== log =="
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | tail -14
echo "== snap =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action snap >/dev/null 2>&1
sleep 2.5
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -1

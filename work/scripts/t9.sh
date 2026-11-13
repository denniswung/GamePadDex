#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
pkill -f gpminput 2>/dev/null; sleep 0.3
rm -f /data/local/tmp/snap_*.png
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 2.0
settings put secure enabled_accessibility_services ""
sleep 0.3
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 4
logcat -c
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 1.2
# put the pointer on the centre of the pillipius icon and double click it
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action debug --ef mx 1208 --ef my 838 >/dev/null 2>&1
sleep 0.6
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action debug --ez double true >/dev/null 2>&1
sleep 2.5
logcat -d -s GpmService:V GpmPointer:V 2>/dev/null | tail -8
echo "=== focused app ==="
dumpsys window 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp" | head -6
echo "=== snap ==="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action snap >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -1

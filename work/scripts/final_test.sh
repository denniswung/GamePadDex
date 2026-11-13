#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SVC=$PKG/$PKG.MouseAccessibilityService
SOCK=/data/data/$PKG/files/gpm.sock
A11Y="$SVC:io.github.sds100.keymapper/io.github.sds100.keymapper.system.accessibility.MyAccessibilityService"

echo "=== 1) restart root helper (socket) ==="
pkill -f gpminput 2>/dev/null
sleep 0.6
rm -f $SOCK
nohup /data/adb/gpm/gpminput --socket $SOCK >/dev/null 2>&1 &
sleep 1.5
ls -l $SOCK 2>&1

echo "=== 2) enable accessibility ==="
settings put secure enabled_accessibility_services "$A11Y"
settings put secure accessibility_enabled 1
sleep 3
logcat -c

echo "=== 3) launch UI ==="
am start -n $PKG/.MainActivity >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | tail -8

echo "=== 4) mouse mode ON (native pointer + grab) ==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode on >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -1

echo "=== 5) move with virtual gamepad stick ==="
(/data/local/tmp/vgpad stick 0 26000 700 2400 >/dev/null 2>&1 &)
sleep 4
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | grep -E "gamepad:|grabbed|devices" | tail -4

echo "=== 6) right click (native mouse) ==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ez double true >/dev/null 2>&1
sleep 1.5
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2.5
logcat -d -s GpmService:V 2>/dev/null | grep -E "SNAP|double tap" | tail -2

echo "=== 7) leave clean: mouse mode OFF ==="
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --es mode off >/dev/null 2>&1
sleep 1
logcat -d -s GpmService:V 2>/dev/null | grep -E "mouse mode" | tail -1
ls -l /data/data/$PKG/files/*.png 2>/dev/null | tail -2

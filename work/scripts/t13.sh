#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput
chmod 755 $BIN
pkill -f gpminput 2>/dev/null
sleep 0.6
rm -f $SOCK
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 1.5
settings put secure enabled_accessibility_services ""
sleep 0.4
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 3
input keyevent KEYCODE_HOME
sleep 1
echo "== toggle ON (native pointer) =="
am broadcast -a $PKG.TOGGLE -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
echo "== snap A =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
echo "== move pointer with stick (native rel) =="
(/data/local/tmp/vgpad stick 0 25000 800 2200 >/dev/null 2>&1 &)
sleep 4
echo "== right click =="
logcat -c
am broadcast -a $PKG.DEBUG -n $PKG/.DebugReceiver --ez double true >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V GpmPointer:V GpmRootInput:V 2>/dev/null | tail -8
echo "== snap B =="
am broadcast -a $PKG.SNAP -n $PKG/.DebugReceiver >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V 2>/dev/null | grep SNAP | tail -2

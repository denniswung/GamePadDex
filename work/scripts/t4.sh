#!/system/bin/sh
PKG=com.dennis.gamepadmouse
SOCK=/data/data/$PKG/files/gpm.sock
BIN=/data/local/tmp/gpminput

echo "== stop old helper =="
pkill -f gpminput 2>/dev/null
sleep 0.5
mkdir -p /data/data/$PKG/files
chmod 777 /data/data/$PKG/files 2>/dev/null

echo "== start helper (socket mode) =="
nohup $BIN --socket $SOCK >/data/local/tmp/gpminput.socklog 2>&1 &
sleep 1
ls -l $SOCK 2>/dev/null
cat /data/local/tmp/gpminput.socklog 2>/dev/null | head -5

echo "== restart accessibility service =="
settings put secure enabled_accessibility_services ""
sleep 0.5
settings put secure enabled_accessibility_services "$PKG/$PKG.MouseAccessibilityService"
sleep 2.5
logcat -c

echo "== toggle mouse ON =="
am start -a android.intent.action.MAIN -n $PKG/.MainActivity -e action toggle >/dev/null 2>&1
sleep 2
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | tail -12

echo "== create virtual gamepad + stick =="
/data/local/tmp/vgpad stick 0 30000 1500 2>/dev/null
sleep 1
echo "-- log --"
logcat -d -s GpmService:V GpmRootInput:V GpmPointer:V 2>/dev/null | tail -15
echo "-- helper out --"
cat /data/local/tmp/gpminput.socklog 2>/dev/null | tail -10
echo "-- cursor window --"
dumpsys window windows 2>/dev/null | grep -A3 "u0 $PKG}:" | grep "mAttrs=" | head -4
